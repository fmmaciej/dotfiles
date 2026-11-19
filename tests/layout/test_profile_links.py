"""Real Stow checks against synthetic HOME/profile directories, never live config."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
PACKAGES = ("common", "powershell", "starship", "tmux", "vim", "wezterm", "yazi")
PROFILES = ("profile.ps1", "Microsoft.PowerShell_profile.ps1")


@unittest.skipUnless(shutil.which("stow") and shutil.which("bash"), "Stow and Bash are required")
class ProfileLinkTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="dotfiles-profiles-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.repo = self.root / "checkout with spaces"
        for package in PACKAGES:
            source = self.repo / package / ".config" / f"{package}.txt"
            source.parent.mkdir(parents=True)
            source.write_text(f"synthetic {package}\n")
        for edition in ("PowerShell", "WindowsPowerShell"):
            for name in PROFILES:
                source = self.repo / "powershell" / "Documents" / edition / name
                source.parent.mkdir(parents=True, exist_ok=True)
                source.write_text(f"# synthetic {edition}/{name}\n")
        documents = self.root / "OneDrive - Fixture [Personal]" / "Documents"
        self.pwsh = documents / "PowerShell"
        self.windows = documents / "WindowsPowerShell"
        tools = self.root / "tools"
        tools.mkdir()
        cygpath = tools / "cygpath"
        cygpath.write_text('#!/bin/sh\n[ "$1" = "-u" ] || exit 2\nprintf \'%s\\n\' "$2"\n')
        cygpath.chmod(0o755)
        self.env = os.environ | {"HOME": str(self.home), "PATH": str(tools) + os.pathsep + os.environ["PATH"]}
        for name in ("STOW_DIR", "STOW_TARGET", "PERL5LIB", "PERL5OPT"):
            self.env.pop(name, None)
        source = (REPO / "scripts/windows/dotfiles.ps1").read_text()
        self.deploy_command = re.search(r"\$Deploy = @'\n(.*?)\n'@", source, re.S).group(1)

    def deploy(self):
        return subprocess.run(
            ["bash", "-c", self.deploy_command, "dotfiles", str(self.repo), str(self.home), str(self.pwsh), str(self.windows)],
            cwd=self.root, env=self.env, capture_output=True, text=True,
        )

    def assert_links(self):
        for package in PACKAGES:
            link = self.home / ".config" / f"{package}.txt"
            self.assertTrue(link.is_symlink(), link)
            self.assertEqual(link.resolve(), self.repo / package / ".config" / f"{package}.txt")
        for directory, edition in ((self.pwsh, "PowerShell"), (self.windows, "WindowsPowerShell")):
            self.assertTrue(directory.is_dir())
            self.assertFalse(directory.is_symlink(), "Do not replace profile directories")
            for name in PROFILES:
                link = directory / name
                self.assertTrue(link.is_symlink(), link)
                self.assertEqual(link.resolve(), self.repo / "powershell" / "Documents" / edition / name)

    def test_redirected_profiles_and_rerun_preserve_existing_documents(self):
        unrelated = self.home / "Documents" / "keep.txt"
        unrelated.parent.mkdir()
        unrelated.write_text("existing local document")
        for directory in (self.pwsh, self.windows):
            directory.mkdir(parents=True)
            (directory / "keep.txt").write_text("existing redirected document")
        for _ in range(2):
            result = self.deploy()
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assert_links()
            self.assertEqual(unrelated.read_text(), "existing local document")
            self.assertFalse((self.home / "Documents" / "PowerShell").exists())
            self.assertFalse((self.home / "Documents" / "WindowsPowerShell").exists())
            for directory in (self.pwsh, self.windows):
                self.assertEqual((directory / "keep.txt").read_text(), "existing redirected document")

    def test_default_profile_directories(self):
        self.pwsh = self.home / "Documents" / "PowerShell"
        self.windows = self.home / "Documents" / "WindowsPowerShell"
        result = self.deploy()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_links()

    def test_conflicts_in_any_target_stop_before_linking(self):
        for target in (self.home / ".config" / "common.txt", self.pwsh / "profile.ps1", self.windows / "profile.ps1"):
            with self.subTest(target=target):
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("existing user file")
                result = self.deploy()
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(target.read_text(), "existing user file")
                for root in (self.home, self.pwsh, self.windows):
                    self.assertFalse(any(path.is_symlink() for path in root.rglob("*")), root)
                target.unlink()  # Only this synthetic conflict fixture is removed.


if __name__ == "__main__":
    unittest.main()
