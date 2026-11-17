"""Hermetic WSL shell checks; no real app, account, or Windows process is used."""

import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest


REPO = Path(__file__).resolve().parents[2]
RC = REPO / "bash/.bashrc"
OPEN = REPO / "bash/.local/bin/wsl-open"


class Fixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="wsl-shell-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.start = self.home / "starting directory"
        self.start.mkdir()
        self.bin = self.home / "mocks"
        self.bin.mkdir()
        (self.home / ".bashrc").symlink_to(RC)
        config = self.home / ".config/bash"
        config.mkdir(parents=True)
        (config / "flyline.bash").symlink_to(REPO / "bash/.config/bash/flyline.bash")
        self.env = {
            "HOME": str(self.home), "PATH": f"{self.bin}:/usr/bin:/bin", "TERM": "xterm-256color",
            "TMPDIR": str(self.home), "XDG_CONFIG_HOME": str(self.home / ".config"),
            "INIT_LOG": str(self.home / "init.log"), "BIND_LOG": str(self.home / "bind.log"),
        }

    def command(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)

    def bash(self, code, interactive=True, extra=None):
        flags = ["--noprofile", "--norc"] + (["-i"] if interactive else [])
        return subprocess.run(
            ["/bin/bash", *flags, "-c", 'source "$1"; shift; ' + code, "test", str(RC)],
            cwd=self.start, env=self.env | (extra or {}), capture_output=True, text=True,
        )


class ShellTests(Fixture):
    def test_noninteractive_does_not_initialize_tools(self):
        self.command("atuin", 'printf unexpected > "$INIT_LOG"')
        r = self.bash('[[ -z ${_DOTFILES_TOOLS_INITIALIZED+x} ]]', interactive=False)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse((self.home / "init.log").exists())

    def test_missing_optional_tools_keeps_readline_and_bash_history(self):
        r = self.bash('[[ "$_DOTFILES_LINE_EDITOR" == readline && "$_DOTFILES_HISTORY_BACKEND" == bash ]] && ! declare -F kei')
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_flyline_never_loads_without_a_terminal(self):
        r = self.bash('[[ $_DOTFILES_FLYLINE_STATE == skipped && $_DOTFILES_LINE_EDITOR == readline ]]')
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_inherited_init_marker_does_not_disable_a_new_process(self):
        r = self.bash('[[ $_DOTFILES_LINE_EDITOR == readline && $_DOTFILES_HISTORY_BACKEND == bash ]]', extra={"_DOTFILES_TOOLS_INITIALIZED": "1", "_DOTFILES_TOOLS_PID": "0"})
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_reload_does_not_duplicate_paths_or_tool_initializers(self):
        self.command("atuin", '''
printf 'atuin %s\n' "$*" >> "$INIT_LOG"
cat <<'EOS'
__atuin_initialized=true
bash_preexec_imported=defined
atuin-bind() { printf '%s\n' "$*" >> "$BIND_LOG"; }
EOS''')
        self.command("starship", '''printf 'starship %s\n' "$*" >> "$INIT_LOG"; printf '_MOCK_STARSHIP_READY=1\n' ''')
        self.command("zoxide", '''printf 'zoxide %s\n' "$*" >> "$INIT_LOG"; printf '_MOCK_ZOXIDE_READY=1\n' ''')
        r = self.bash('before="$PATH"; source "$HOME/.bashrc"; [[ "$PATH" == "$before" && "$_DOTFILES_HISTORY_BACKEND" == atuin && -z "$HISTFILE" ]]')
        self.assertEqual(r.returncode, 0, r.stderr)
        log = (self.home / "init.log").read_text().splitlines()
        self.assertEqual(len(log), 3)
        self.assertTrue(log[0].startswith("atuin init bash --disable-up-arrow --disable-ctrl-r --disable-ai"))
        self.assertEqual(log[1], "zoxide init bash --no-cmd")
        self.assertEqual(log[2], "starship init bash")
        bindings = (self.home / "bind.log").read_text()
        self.assertIn("-m emacs", bindings)
        self.assertIn("-m vi-insert", bindings)
        self.assertNotIn("vi-command", bindings)
        self.assertNotIn("import", "\n".join(log))
        self.assertNotIn("sync", "\n".join(log))

    def test_failed_atuin_keeps_existing_bash_history(self):
        self.command("atuin", "exit 12")
        r = self.bash('[[ "$_DOTFILES_HISTORY_BACKEND" == bash && "$HISTFILE" == "$HOME/history" ]]', extra={"HISTFILE": str(self.home / "history")})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("Atuin initialization failed", r.stderr)

    def test_atuin_without_preexec_keeps_bash_history(self):
        self.command("atuin", "printf '%s\\n' '__atuin_initialized=true' 'atuin-bind() { :; }'")
        r = self.bash('[[ "$_DOTFILES_HISTORY_BACKEND" == bash && "$HISTFILE" == "$HOME/history" ]]', extra={"HISTFILE": str(self.home / "history")})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("preexec hooks are unavailable", r.stderr)

    def test_dot_uses_the_home_checkout_from_another_directory(self):
        self.command("git", "printf '%s\\n' \"$@\"")
        r = self.bash("dot status")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.splitlines(), ["-C", str(self.home / ".dotfiles"), "status"])

    def test_yazi_changes_directory_and_removes_cwd_file(self):
        destination = self.home / "selected directory"
        destination.mkdir()
        self.command("yazi", '''
for arg; do
  case "$arg" in --cwd-file=*) file="${arg#--cwd-file=}";; esac
done
printf '%s' "$SELECTED" > "$file"
printf '%s' "$file" > "$HOME/cwd-file-path"
exit "${MOCK_EXIT:-0}"''')
        r = self.bash('y "two words" && pwd', extra={"SELECTED": str(destination)})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.strip(), str(destination))
        self.assertFalse(Path((self.home / "cwd-file-path").read_text()).exists())

    def test_yazi_failure_preserves_directory_and_exit_status(self):
        self.command("yazi", "exit 7")
        r = self.bash('y; status=$?; printf "%s\\n%s\\n" "$status" "$PWD"')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.splitlines(), ["7", str(self.start)])
        self.assertFalse(list(self.home.glob("yazi-cwd.*")))

    def test_zi_uses_skim_and_does_not_call_fzf(self):
        destination = self.home / "ranked directory"
        destination.mkdir()
        self.command("zoxide", '''if [[ "$1" == init ]]; then exit 0; fi; printf '%s\n' "$SELECTED" ''')
        self.command("sk", "IFS= read -r selected; printf '%s\\n' \"$selected\"")
        self.command("fzf", 'printf unexpected > "$HOME/fzf-called"; exit 99')
        r = self.bash('zi && pwd', extra={"SELECTED": str(destination)})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.strip(), str(destination))
        self.assertFalse((self.home / "fzf-called").exists())

    def test_cancelled_picker_keeps_directory(self):
        self.command("zoxide", '''if [[ "$1" == init ]]; then exit 0; fi; printf '/unused\n' ''')
        self.command("sk", "exit 130")
        r = self.bash('zi; printf "%s\\n" "$PWD"')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.strip(), str(self.start))

    def test_config_files_parse_and_history_sync_is_off(self):
        atuin = tomllib.loads((REPO / "atuin/.config/atuin/config.toml").read_text())
        self.assertFalse(atuin["auto_sync"])
        self.assertFalse(atuin["enter_accept"])
        starship = tomllib.loads((REPO / "starship/.config/starship.toml").read_text())
        self.assertIn("$time", starship["format"])
        yazi = tomllib.loads((REPO / "yazi/.config/yazi/yazi.toml").read_text())
        self.assertFalse(yazi["mgr"]["sort_sensitive"])
        self.assertEqual(yazi["opener"]["open"][0]["run"], "wsl-open %s1")


class OpenTests(Fixture):
    def test_wslview_is_preferred(self):
        self.command("wslview", "printf '%s\\n' \"$@\"")
        r = subprocess.run([str(OPEN), "two words"], env=self.env, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.strip(), "two words")

    def test_explorer_fallback_receives_the_converted_path(self):
        self.command("wslpath", '''printf '%s\n' "$*" > "$HOME/wslpath-args"; printf '%s\n' 'C:/fixture/two words' ''')
        self.command("explorer.exe", "printf '%s\\n' \"$@\"")
        r = subprocess.run([str(OPEN), "two words"], cwd=self.start, env=self.env, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.strip(), "C:/fixture/two words")
        self.assertEqual((self.home / "wslpath-args").read_text().strip(), f"-w {self.start}/two words")

    def test_missing_interop_is_a_clear_error(self):
        r = subprocess.run([str(OPEN), "file"], env=self.env, capture_output=True, text=True)
        self.assertEqual(r.returncode, 127)
        self.assertIn("Windows interop", r.stderr)


if __name__ == "__main__":
    unittest.main()
