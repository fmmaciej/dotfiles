#!/usr/bin/env bash
set -euo pipefail

# Experimental Vim fork: exact release and artifact bytes, never "latest".
TAG='remote-ssh-v1.10.0-pr974.aae68bb4.r5-linux.1'
ASSET='flyline-1.10.0-pr974.aae68bb4.r5-x86_64-unknown-linux-gnu.tar.gz'
SHA256='4c671e22ed701893163f9cbd3a7d2f54d7e3584f23b8d83825e06d7750be131e'
URL="https://github.com/fmmaciej/flyline/releases/download/$TAG/$ASSET"

die() { printf 'flyline install: %s\n' "$*" >&2; exit 1; }
if [[ ${1:-} == --help ]]; then
  printf 'Usage: %s [LOCAL_ARCHIVE]\nDownload the pinned release, or install its exact local archive.\n' "$0"
  exit 0
fi
[[ $# -le 1 ]] || die "Usage: $0 [LOCAL_ARCHIVE]"
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || die 'Requires x86_64 Linux, not macOS.'
libc=$(getconf GNU_LIBC_VERSION 2>/dev/null) || die 'Requires glibc, not musl.'
[[ $libc =~ ^glibc\ ([0-9]+)\.([0-9]+) ]] || die 'Requires glibc, not musl.'
((BASH_REMATCH[1] > 2 || (BASH_REMATCH[1] == 2 && BASH_REMATCH[2] >= 39))) || die 'This binary requires glibc 2.39+; tested on 2.41.'
[[ ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} == 5.3 ]] || die 'This WSL profile requires Bash 5.3.'
for tool in tar sha256sum mktemp cp cmp chmod mv ln readlink sort od tr grep; do
  command -v "$tool" >/dev/null || die "Missing command: $tool"
done
if [[ $# == 0 ]]; then command -v curl >/dev/null || die 'Missing command: curl'; fi

prefix="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/flyline"
release="$prefix/$SHA256"
[[ $prefix == /* ]] || die 'XDG_DATA_HOME must be absolute.'
if [[ -L $prefix/current ]]; then
  previous=$(readlink -- "$prefix/current")
  [[ $previous == "$prefix/"* && ${previous#"$prefix/"} =~ ^[0-9a-f]{64}$ ]] || die 'Refusing to replace an unmanaged current symlink.'
elif [[ -e $prefix/current ]]; then
  die 'Refusing to replace a non-symlink current path.'
fi
mkdir -p -- "$prefix"
work=$(mktemp -d "$prefix/.install-XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
if [[ $# == 1 ]]; then
  cp -- "$1" "$work/archive.tar.gz"
else
  curl --fail --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --connect-timeout 15 --max-time 180 --retry 2 --output "$work/archive.tar.gz" "$URL" ||
    die "Could not download $URL. The release must be published first."
fi
printf '%s  %s\n' "$SHA256" "$work/archive.tar.gz" | sha256sum --check --status || die 'SHA-256 mismatch; nothing installed.'
members=$(tar -tzf "$work/archive.tar.gz" | LC_ALL=C sort)
[[ $members == $'LICENSE-GPLv3\nLICENSE-MIT\nlibflyline.so\nprovenance.json' ]] || die 'Unexpected archive contents.'
mkdir "$work/payload"
for name in libflyline.so LICENSE-MIT LICENSE-GPLv3 provenance.json; do
  # Stream only named bytes; never extract archive paths, permissions or links.
  tar -xOzf "$work/archive.tar.gz" "$name" > "$work/payload/$name"
done
grep -Fq '"source_commit": "d037c075ed30a61080873985ea2621d743ddfc64"' "$work/payload/provenance.json" || die 'Unexpected source commit.'
grep -Fq '"target": "x86_64-unknown-linux-gnu"' "$work/payload/provenance.json" || die 'Unexpected library target.'
header=$(od -An -tx1 -N20 "$work/payload/libflyline.so" | tr -d ' \n')
[[ ${header:0:12} == 7f454c460201 && ${header:32:8} == 03003e00 ]] || die 'Expected an x86_64 ELF shared library.'
chmod 755 "$work/payload/libflyline.so"
chmod 644 "$work/payload/"LICENSE-* "$work/payload/provenance.json"
if [[ -e $release || -L $release ]]; then
  [[ -d $release && ! -L $release ]] || die 'Refusing a conflicting release path.'
  for name in libflyline.so LICENSE-MIT LICENSE-GPLv3 provenance.json; do
    if [[ ! -f $release/$name || -L $release/$name ]] || ! cmp -s "$work/payload/$name" "$release/$name"; then
      die 'Existing release differs; refusing to overwrite it.'
    fi
  done
else
  mv -- "$work/payload" "$release"
fi
ln -s -- "$release" "$work/current"
mv -Tf -- "$work/current" "$prefix/current"
printf 'Installed %s\nFlyline loads automatically in new interactive Bash sessions using the dotfiles configuration.\n' "$release/libflyline.so"
