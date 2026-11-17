"""Hermetic release installer and loader checks; no actual GitHub download."""

import hashlib
import io
import json
import os
import pty
import re
import shutil
import subprocess
import tarfile
import unittest

from test_shell import Fixture, REPO


INSTALLER = REPO / "scripts/install-flyline.sh"


class InstallerTests(Fixture):
    def setUp(self):
        super().setUp()
        self.bash_path = shutil.which("bash")
        version = subprocess.check_output([self.bash_path, "-c", 'printf "%s.%s" "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}"'], text=True)
        if version != "5.3":
            self.skipTest("Installer requires the target Bash 5.3")
        self.prefix = self.home / ".local/share/dotfiles/flyline"
        self.command("uname", 'if [[ "$1" == -s ]]; then printf "%s\\n" "${MOCK_SYSTEM:-Linux}"; else printf "x86_64\\n"; fi')
        self.command("getconf", 'printf "%s\\n" "${MOCK_LIBC:-glibc 2.41}"')
        for tool in ("sha256sum", "mv"):
            # GNU mv's -T is required on the actual Linux target.
            executable = shutil.which("g" + tool) or shutil.which(tool)
            (self.bin / tool).symlink_to(executable)
        self.command("curl", '''
[[ ${FAIL_DOWNLOAD:-0} != 1 ]] || exit 22
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) shift; output="$1" ;;
    https://*) printf '%s\\n' "$1" > "$HOME/download-url" ;;
  esac
  shift
done
cp "$FIXTURE_ARCHIVE" "$output"
''')
        library = bytearray(64)
        library[:6] = b"\x7fELF\x02\x01"
        library[16:20] = b"\x03\x00\x3e\x00"
        self.files = {"libflyline.so": bytes(library), "LICENSE-MIT": b"Test MIT license\n", "LICENSE-GPLv3": b"Test GPL license\n"}
        self.provenance = {
            "source_commit": "d037c075ed30a61080873985ea2621d743ddfc64",
            "target": "x86_64-unknown-linux-gnu", "library_member": "libflyline.so",
            "library_sha256": hashlib.sha256(library).hexdigest(),
        }

    def archive(self, extra=None):
        files = self.files | {"provenance.json": json.dumps(self.provenance, indent=2).encode()}
        path = self.home / "artifact.tar.gz"
        with tarfile.open(path, "w:gz") as package:
            for name, data in files.items():
                info = tarfile.TarInfo(name)
                info.size = len(data)
                package.addfile(info, io.BytesIO(data))
            if extra:
                package.addfile(extra, io.BytesIO(b""))
        return path, hashlib.sha256(path.read_bytes()).hexdigest()

    def install(self, archive, digest, download=False, extra=None):
        # Only the isolated fixture copy gets a synthetic digest; production pins
        # the real release bytes and has no checksum/version environment override.
        source = INSTALLER.read_text()
        self.assertRegex(source, r"SHA256='[0-9a-f]{64}'")
        script = self.home / "install-fixture.sh"
        script.write_text(re.sub(r"(?m)^SHA256='[^']+'$", f"SHA256='{digest}'", source))
        args = [] if download else [str(archive)]
        return subprocess.run([self.bash_path, str(script), *args], env=self.env | {"FIXTURE_ARCHIVE": str(archive)} | (extra or {}), capture_output=True, text=True, timeout=10)

    def test_valid_local_install_is_idempotent(self):
        archive, digest = self.archive()
        for _ in range(2):
            result = self.install(archive, digest)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.prefix / "current").resolve(), self.prefix / digest)
        self.assertEqual((self.prefix / "current/libflyline.so").read_bytes(), self.files["libflyline.so"])
        self.assertFalse(list(self.prefix.glob(".install-*")))

    def test_download_uses_the_exact_fork_release_not_latest(self):
        archive, digest = self.archive()
        result = self.install(archive, digest, download=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / "download-url").read_text().strip(),
                         "https://github.com/fmmaciej/flyline/releases/download/remote-ssh-v1.10.0-pr974.aae68bb4.r5-linux.1/flyline-1.10.0-pr974.aae68bb4.r5-x86_64-unknown-linux-gnu.tar.gz")

    def test_checksum_failure_installs_nothing_and_cleans_its_stage(self):
        archive, _ = self.archive()
        result = self.install(archive, "0" * 64)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SHA-256 mismatch", result.stderr)
        self.assertFalse((self.prefix / "current").exists())
        self.assertFalse(list(self.prefix.glob(".install-*")))

    def test_missing_release_is_a_clear_failure(self):
        archive, digest = self.archive()
        result = self.install(archive, digest, download=True, extra={"FAIL_DOWNLOAD": "1"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("release must be published first", result.stderr)
        self.assertFalse((self.prefix / "current").exists())

    def test_wrong_source_and_target_are_rejected(self):
        self.provenance["source_commit"] = "wrong"
        archive, digest = self.archive()
        result = self.install(archive, digest)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unexpected source commit", result.stderr)

    def test_unsafe_and_duplicate_members_are_rejected(self):
        for name, kind in (("../outside", tarfile.REGTYPE), ("libflyline.so", tarfile.REGTYPE),
                           ("extra", tarfile.SYMTYPE), ("extra", tarfile.LNKTYPE)):
            with self.subTest(name=name, kind=kind):
                member = tarfile.TarInfo(name)
                member.type = kind
                member.linkname = str(self.home / "outside")
                archive, digest = self.archive(member)
                result = self.install(archive, digest)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Unexpected archive contents", result.stderr)
        self.assertFalse((self.home / "outside").exists())

    def test_non_elf_library_is_rejected(self):
        self.files["libflyline.so"] = b"not an ELF library"
        archive, digest = self.archive()
        result = self.install(archive, digest)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ELF", result.stderr)

    def test_existing_user_file_is_not_replaced(self):
        self.prefix.mkdir(parents=True)
        (self.prefix / "current").write_text("user file")
        archive, digest = self.archive()
        result = self.install(archive, digest)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("non-symlink", result.stderr)
        self.assertEqual((self.prefix / "current").read_text(), "user file")

    def test_corrupted_release_is_not_overwritten_and_current_is_preserved(self):
        archive, digest = self.archive()
        result = self.install(archive, digest)
        self.assertEqual(result.returncode, 0, result.stderr)
        library = self.prefix / digest / "libflyline.so"
        library.write_bytes(b"user changes")
        result = self.install(archive, digest)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Existing release differs", result.stderr)
        self.assertEqual(library.read_bytes(), b"user changes")
        self.assertEqual((self.prefix / "current").resolve(), self.prefix / digest)

    def test_unmanaged_current_symlink_is_preserved(self):
        self.prefix.mkdir(parents=True)
        current = self.prefix / "current"
        current.symlink_to(self.home / "unmanaged")
        archive, digest = self.archive()
        result = self.install(archive, digest)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unmanaged", result.stderr)
        self.assertEqual(current.readlink(), self.home / "unmanaged")

    def test_macos_musl_and_old_glibc_are_rejected_before_downloading(self):
        archive, digest = self.archive()
        for environment in ({"MOCK_SYSTEM": "Darwin"}, {"MOCK_LIBC": "musl"}, {"MOCK_LIBC": "glibc 2.38"}):
            with self.subTest(environment=environment):
                result = self.install(archive, digest, download=True, extra=environment)
                self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / "download-url").exists())


class LoaderTests(Fixture):
    def simulate(self, extra=None, before=""):
        bash = shutil.which("bash")
        version = subprocess.check_output([bash, "--noprofile", "--norc", "-c", 'printf "%s.%s" "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}"'], text=True)
        if version != "5.3":
            self.skipTest("Loader mock tests require Bash 5.3 (the target version)")
        prefix = self.home / ".local/share/dotfiles/flyline"
        library = prefix / ("a" * 64) / "libflyline.so"
        library.parent.mkdir(parents=True)
        (prefix / "current").symlink_to(library.parent, target_is_directory=True)
        library.write_text("Synthetic fixture, never loaded")
        rc = self.home / "mock-rc"
        rc.write_text('''
# These host markers and builtin calls are mocked, not native Linux evidence.
OSTYPE=linux-gnu
HOSTTYPE=x86_64
builtin() {
  case "$1:$2" in
    enable:-f)
      printf 'load\n' >> "$HOME/flyline-log"
      printf 'library=%s\n' "$3" >> "$HOME/flyline-log"
      export FLYLINE_VERSION=mock FLYLINE_LOAD_DIR=mock
      [[ ${FAIL_LOAD:-0} != 1 ]]
      ;;
    enable:-d)
      printf 'unload\n' >> "$HOME/flyline-log"
      [[ ${FAIL_UNLOAD:-0} != 1 ]]
      ;;
    flyline:*)
      printf '%s\n' "$*" >> "$HOME/flyline-log"
      [[ ${FAIL_SETTINGS:-0} != 1 ]]
      ;;
    *) command builtin "$@" ;;
  esac
}
''' + before + '''
source "$HOME/.bashrc"
source "$HOME/.bashrc"
printf '%s %s %s\n' "$_DOTFILES_LINE_EDITOR" "$_DOTFILES_HISTORY_BACKEND" "$_DOTFILES_FLYLINE_STATE" > "$HOME/result"
declare -p FLYLINE_LOAD_DIR FLYLINE_VERSION > "$HOME/markers" 2>/dev/null || :
''')
        master, slave = pty.openpty()
        try:
            result = subprocess.run([bash, "--noprofile", "--rcfile", str(rc), "-ic", "exit"],
                                    env=self.env | (extra or {}), stdin=slave, stdout=slave,
                                    stderr=subprocess.PIPE, text=True, timeout=10)
        finally:
            os.close(slave)
            os.close(master)
        self.assertEqual(result.returncode, 0, result.stderr)
        log = self.home / "flyline-log"
        return (self.home / "result").read_text().strip(), log.read_text() if log.exists() else ""

    def test_default_keeps_readline_even_with_an_installed_library(self):
        state, log = self.simulate()
        self.assertEqual(state, "readline bash disabled")
        self.assertEqual(log, "")

    def test_enabled_editor_uses_vim_bash_history_and_skim_without_reload(self):
        self.command("sk", "exit 0")
        state, log = self.simulate({"DOTFILES_ENABLE_FLYLINE": "1"})
        self.assertEqual(state, "flyline bash active")
        self.assertEqual(log.splitlines().count("load"), 1)
        self.assertIn("key --vim-mode true", log)
        self.assertIn("history --backend bash", log)
        self.assertIn("vimInsertMode=runBashCommand(_dotfiles_history)", log)
        self.assertNotIn("/current/libflyline.so", log)
        self.assertIn("/" + "a" * 64 + "/libflyline.so", log)

    def test_atuin_history_owns_storage_and_insert_search_only(self):
        self.command("atuin", "printf '%s\\n' '__atuin_initialized=true' 'bash_preexec_imported=defined' 'atuin-bind() { :; }' '__atuin_history() { :; }'")
        state, log = self.simulate({"DOTFILES_ENABLE_FLYLINE": "1"})
        self.assertEqual(state, "flyline atuin active")
        self.assertIn("vimInsertMode=runBashCommand(_dotfiles_flyline_history_vi)", log)
        self.assertNotIn("vimNormalMode=", log)

    def test_failed_load_restores_readline_and_inherited_environment(self):
        state, log = self.simulate({"DOTFILES_ENABLE_FLYLINE": "1", "FAIL_LOAD": "1", "FLYLINE_VERSION": "inherited", "FLYLINE_LOAD_DIR": "previous"})
        self.assertEqual(state, "readline bash failed")
        markers = (self.home / "markers").read_text()
        self.assertIn('declare -x FLYLINE_VERSION="inherited"', markers)
        self.assertIn('declare -x FLYLINE_LOAD_DIR="previous"', markers)
        self.assertNotIn("unload", log)

    def test_atuin_nobind_preserves_the_users_search_bindings(self):
        self.command("atuin", "printf '%s\\n' '__atuin_initialized=true' 'bash_preexec_imported=defined' 'atuin-bind() { :; }' '__atuin_history() { :; }'")
        state, log = self.simulate({"DOTFILES_ENABLE_FLYLINE": "1", "ATUIN_NOBIND": "1"})
        self.assertEqual(state, "flyline atuin active")
        self.assertNotIn("bind Ctrl+r", log)

    def test_failed_settings_unload_before_readline_fallback(self):
        state, log = self.simulate({"DOTFILES_ENABLE_FLYLINE": "1", "FAIL_SETTINGS": "1"})
        self.assertEqual(state, "readline bash failed")
        self.assertIn("unload", log)
        self.assertEqual((self.home / "markers").read_text(), "")

    def test_failed_unload_does_not_claim_readline_recovery(self):
        state, log = self.simulate({"DOTFILES_ENABLE_FLYLINE": "1", "FAIL_SETTINGS": "1", "FAIL_UNLOAD": "1"})
        self.assertEqual(state, "flyline bash rollback-failed")
        self.assertIn("unload", log)

    def test_external_editor_is_not_taken_over(self):
        state, log = self.simulate({"DOTFILES_ENABLE_FLYLINE": "1"}, before="flyline() { :; }\n")
        self.assertEqual(state, "readline bash skipped")
        self.assertEqual(log, "")


if __name__ == "__main__":
    unittest.main()
