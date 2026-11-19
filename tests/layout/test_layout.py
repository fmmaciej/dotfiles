"""Portable layout/ignore checks; native PowerShell tests are separate."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
PACKAGES = ("common", "opencode", "powershell", "starship", "tmux", "vim", "wezterm", "yazi")
EXPECTED = {
    "common": (".editorconfig",),
    "opencode": (
        ".config/opencode/cli.json",
        ".config/opencode/plugins/personal-ui/package.json",
        ".config/opencode/plugins/personal-ui/state.mjs",
        ".config/opencode/plugins/personal-ui/tui.tsx",
        ".config/opencode/plugins/personal-ui/vendor/LICENSE",
        ".config/opencode/plugins/personal-ui/vendor/README.md",
        ".config/opencode/plugins/personal-ui/vendor/vim.d.ts",
        ".config/opencode/plugins/personal-ui/vendor/vim.js",
    ),
    "powershell": (
        ".config/powershell/10-environment.ps1",
        ".config/powershell/15-readline.ps1",
        ".config/powershell/20-skim.ps1",
        ".config/powershell/30-proxy.ps1",
        ".config/powershell/40-aliases.ps1",
        ".config/powershell/50-dotfiles.ps1",
        ".config/powershell/90-prompt.ps1",
        ".config/powershell/profile.ps1",
        ".config/powershell/proxy.local.example.psd1",
        "Documents/PowerShell/profile.ps1",
        "Documents/PowerShell/Microsoft.PowerShell_profile.ps1",
        "Documents/WindowsPowerShell/profile.ps1",
        "Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1",
    ),
    "starship": (".config/starship.toml",),
    "tmux": (
        ".tmux.conf", ".tmux/modules/00-core.conf", ".tmux/modules/10-keys.conf",
        ".tmux/modules/20-copy-paste.conf", ".tmux/modules/30-mouse.conf",
        ".tmux/modules/60-theme.conf", ".tmux/themes/vscode-dark-modern/colors.ps1",
        ".tmux/scripts/startup.ps1", ".tmux/scripts/battery.ps1", ".tmux/scripts/paste.ps1",
    ),
    "vim": (".vimrc", "_vimrc", "vimfiles/autoload/plug.vim"),
    "wezterm": (".wezterm.lua", ".config/wezterm/colors/vscode_dark_modern.lua", ".config/wezterm/psmux-session.ps1"),
    "yazi": (".config/yazi/yazi.toml",),
}


class LayoutTests(unittest.TestCase):
    def test_all_existing_configurations_have_package_paths(self):
        for package, paths in EXPECTED.items():
            for path in paths:
                with self.subTest(package=package, path=path):
                    self.assertTrue((REPO / package / path).is_file())
                    self.assertFalse((REPO / path).is_file())

    def test_support_directories_are_separate_from_packages(self):
        for name in ("docs", "scripts", "tests"):
            self.assertTrue((REPO / name).is_dir())
            self.assertNotIn(name, PACKAGES)
        self.assertIn("opencode", PACKAGES)

    def test_copy_mode_half_page_keys_reach_psmux(self):
        bindings = (REPO / "tmux/.tmux/modules/20-copy-paste.conf").read_text()
        terminal = (REPO / "wezterm/.wezterm.lua").read_text()
        for key, action in (("PageUp", "halfpage-up"), ("PageDown", "halfpage-down")):
            self.assertIn(f"bind -T copy-mode-vi S-{key} send-keys -X {action}", bindings)
            self.assertIn(
                f"{{ key = '{key}', mods = 'SHIFT', action = act.DisableDefaultAssignment }}",
                terminal,
            )

    def test_helper_uses_the_source_checkout_and_keeps_git_worktrees_supported(self):
        source = (REPO / "powershell/.config/powershell/50-dotfiles.ps1").read_text()
        self.assertIn('Get-Item -LiteralPath $PSCommandPath', source)
        self.assertIn('$DotfilesHelper.LinkType -eq "SymbolicLink"', source)
        self.assertIn('$DotfilesLinkTarget = @($DotfilesHelper.Target)[0]', source)
        self.assertIn('Test-Path -LiteralPath (Join-Path $DotfilesRepositoryCandidate ".git")', source)
        self.assertIn('& git -C $global:DotfilesRepository @args', source)
        for retired in ("--git-dir", "--work-tree", "dot-sync", "dot-code", "HardLink", "Remove-Item"):
            self.assertNotIn(retired, source)

    def test_new_scripts_have_stable_line_endings(self):
        attributes = (REPO / ".gitattributes").read_text()
        for pattern in ("*.sh text eol=lf", "*.ps1 text eol=lf", "*.psd1 text eol=lf"):
            self.assertIn(pattern, attributes)
        for path in (
            REPO / "scripts/check-tools.sh",
            REPO / "scripts/check-tools.ps1",
            REPO / "powershell/.config/powershell/50-dotfiles.ps1",
            REPO / "tests/powershell/Test-Dotfiles.ps1",
        ):
            self.assertNotIn(b"\r", path.read_bytes())
            if path.suffix == ".ps1":
                path.read_bytes().decode("ascii")

    def test_local_markdown_links_resolve(self):
        files = [REPO / "README.md", *(REPO / "docs").rglob("*.md")]
        for path in files:
            for target in re.findall(r"\]\(([^)]+)\)", path.read_text()):
                if "://" not in target and not target.startswith("#"):
                    self.assertTrue((path.parent / target.split("#", 1)[0]).exists(), (path, target))

    @unittest.skipUnless(shutil.which("git"), "Git is required")
    def test_gitignore_exposes_sources_and_protects_local_state(self):
        env = os.environ | {"GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull}
        for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
            env.pop(name, None)
        with tempfile.TemporaryDirectory(prefix="dotfiles-ignore-", dir=os.environ.get("TMPDIR")) as tmp:
            root = Path(tmp)
            subprocess.run(["git", "init", "--quiet", "--template=", str(root)], env=env, check=True)
            shutil.copyfile(REPO / ".gitignore", root / ".gitignore")
            visible = (
                "README.md", "docs/new.md", "scripts/new.ps1", "tests/new.py",
                "powershell/.config/powershell/profile.ps1",
                "powershell/.config/powershell/proxy.local.example.psd1",
                "opencode/.config/opencode/cli.json",
                "opencode/.config/opencode/plugins/personal-ui/vendor/vim.js",
                "vim/vimfiles/autoload/plug.vim", "example/.env.example",
            )
            private = (
                "powershell/.config/powershell/proxy.local.psd1",
                "example/.env", "example/.env.production", "example/env.local",
                "example/.ssh/id_ed25519", "example/.ssh/config.local",
                "example/.gnupg/secret", "vim/.vim/plugged/example/plugin.vim",
                "vim/.vim/undo/state", "vim/vimfiles/plugged/example/plugin.vim",
                "tmux/.psmux/plugins/example/plugin.ps1", "tests/__pycache__/test.pyc",
                "opencode/.config/opencode/node_modules/example/index.js",
            )
            for paths, expected in ((visible, 1), (private, 0)):
                for path in paths:
                    with self.subTest(path=path):
                        result = subprocess.run(
                            ["git", "-c", f"core.excludesFile={os.devnull}", "check-ignore", "--no-index", "--quiet", "--", path],
                            cwd=root, env=env, capture_output=True, text=True,
                        )
                        self.assertEqual(result.returncode, expected, result.stderr)


if __name__ == "__main__":
    unittest.main()
