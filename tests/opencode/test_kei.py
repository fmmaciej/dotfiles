"""Hermetic tests of the shell entry point; no real OC or editor is started."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[2] / "zsh/.config/zsh/80-kei.zsh"


class KeiTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kei-wrapper-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.root = self.home / "kei instance"
        self.root.mkdir()
        self.start = self.home / "starting directory"
        self.start.mkdir()
        self.wrapper = self.home / "kei.sh"
        source, count = re.subn(r'(?m)^  local root=.*$', '  local root="$HOME/kei instance"', SOURCE.read_text())
        self.assertEqual(count, 1)
        self.wrapper.write_text(source)
        bindir = self.home / "bin"
        bindir.mkdir()
        for name in ("opencode", "code"):
            executable = bindir / name
            executable.write_text('#!/bin/sh\nprintf "cwd=%s\\n" "$PWD"\nfor arg do printf "arg=%s\\n" "$arg"; done\nexit "${MOCK_EXIT:-0}"\n')
            executable.chmod(0o755)
        self.env = {"HOME": str(self.home), "PATH": f"{bindir}:/usr/bin:/bin", "TERM": "xterm-256color"}
        self.shells = [("bash", ["--noprofile", "--norc", "-c"])]
        if shutil.which("zsh"):
            self.shells.append(("zsh", ["-d", "-f", "-c"]))

    def run_shell(self, shell, flags, script, extra=None):
        return subprocess.run(
            [shell, *flags, 'source "$1"; shift; ' + script, "test", str(self.wrapper)],
            cwd=self.start, env=self.env | (extra or {}), capture_output=True, text=True,
        )

    def test_help_and_default_are_equal(self):
        for shell, flags in self.shells:
            with self.subTest(shell=shell):
                default = self.run_shell(shell, flags, "kei")
                help_result = self.run_shell(shell, flags, "kei help")
                self.assertEqual(default.returncode, 0, default.stderr)
                self.assertEqual(default.stdout, help_result.stdout)
                self.assertIn("kei open", default.stdout)
                self.assertIn("kei edit", default.stdout)

    def test_open_changes_the_calling_shell_directory(self):
        for shell, flags in self.shells:
            with self.subTest(shell=shell):
                result = self.run_shell(shell, flags, "kei open && pwd")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), str(self.root))

    def test_run_forwards_arguments_without_changing_parent_directory(self):
        for shell, flags in self.shells:
            with self.subTest(shell=shell):
                result = self.run_shell(shell, flags, 'kei run --continue "two words"; printf "parent=%s\\n" "$PWD"')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), [f"cwd={self.root}", "arg=--continue", "arg=two words", f"parent={self.start}"])

    def test_run_preserves_opencode_exit_status(self):
        for shell, flags in self.shells:
            with self.subTest(shell=shell):
                result = self.run_shell(shell, flags, "kei run", {"MOCK_EXIT": "7"})
                self.assertEqual(result.returncode, 7)

    def test_edit_opens_the_instance_without_changing_directory(self):
        for shell, flags in self.shells:
            with self.subTest(shell=shell):
                result = self.run_shell(shell, flags, "kei edit")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), [f"cwd={self.start}", f"arg={self.root}"])

    def test_unknown_command_fails_with_help(self):
        for shell, flags in self.shells:
            with self.subTest(shell=shell):
                result = self.run_shell(shell, flags, "kei invalid")
                self.assertEqual(result.returncode, 2)
                self.assertIn("unknown command", result.stderr)
                self.assertIn("kei help", result.stderr)

    def test_missing_directory_does_not_start_opencode(self):
        self.root.rmdir()
        for shell, flags in self.shells:
            with self.subTest(shell=shell):
                result = self.run_shell(shell, flags, "kei run")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
