#!/bin/sh
# DropTerm's one-command install: download the release tarball, verify
# the checksums file's SSH signature and then the tarball against the
# verified checksums, and install the usr/ tree into ~/.local. User-level
# only: no sudo; the writes are the binary, the desktop file, the icon,
# the metainfo, the completions data, and one guarded PATH export line
# per shell startup file when needed.
#
# Inspect before running: fetch this file, read it, then run it:
#   curl -fsSL .../install.sh -o install.sh && less install.sh && sh install.sh
#
# The verification is two steps, in order: `sha256sums` is checked
# against its signature with `ssh-keygen -Y verify` (the signing key's
# public half ships as keys/allowed_signers *at the release tag*, so a
# released version always verifies against the keys its tree carried),
# and only then is the tarball checked against the verified checksums.
# This protects the release assets against tampering or substitution;
# it does not protect against a compromise of the repository itself -
# the classic bootstrap gap of `curl | sh`, which is why the script is
# short, commented, and meant to be read first.
#
# Environment:
#   DROPTERM_VERSION=X.Y.Z     release to install (default: latest)
#   DROPTERM_PREFIX=DIR        install root (default: ~/.local; the
#                              tree lands in DIR/bin and DIR/share)
#   DROPTERM_NO_MODIFY_PATH=1  print the PATH line instead of appending
#                              it to shell startup files
#
# Signed checksums ship from v0.6.0; this script refuses older releases.
#
# Uninstall: quit any running instance (tray menu → Quit, or
# `dropterm toggle` … the tray), then remove:
#   $PREFIX/bin/dropterm
#   $PREFIX/share/applications/io.github.l1br3_io.dropterm.desktop
#   $PREFIX/share/metainfo/io.github.l1br3_io.dropterm.metainfo.xml
#   $PREFIX/share/icons/hicolor/scalable/apps/io.github.l1br3_io.dropterm.svg
#   $PREFIX/share/io.github.l1br3_io.dropterm/  (directory)
# plus the PATH lines this script appended to ~/.bashrc / ~/.profile
# (and ~/.zshrc when the shell is zsh). An existing /usr install from
# the release tarball is untouched but shadowed: ~/.local wins on PATH
# and in the app grid; remove it with the README's uninstall steps.
set -eu

repo="l1br3-io/dropterm"
principal="dropterm-release"

die() { printf 'dropterm: error: %s\n' "$*" >&2; exit 1; }
note() { printf 'dropterm: %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

fetch() { # url -> stdout
    if have curl; then
        curl -fsSL --proto '=https' --tlsv1.2 "$1"
    elif have wget; then
        wget -qO- "$1"
    else
        die "curl or wget is required"
    fi
}

download() { # url destination
    if have curl; then
        curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1"
    elif have wget; then
        wget -qO "$2" "$1"
    else
        die "curl or wget is required"
    fi
}

latest_version() {
    api="https://api.github.com/repos/$repo/releases/latest"
    payload="$(fetch "$api")" || die "cannot query the latest release"
    tag="$(printf '%s\n' "$payload" |
        sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)"
    [ -n "$tag" ] || die "cannot read the latest release tag"
    printf '%s' "${tag#v}"
}

resolve_arch() {
    os="$(uname -s)"
    machine="$(uname -m)"
    [ "$os" = "Linux" ] ||
        die "DropTerm runs on Linux only (found $os); build from source for another system"
    case "$machine" in
        x86_64 | amd64) printf '%s' "x86_64" ;;
        aarch64 | arm64) printf '%s' "aarch64" ;;
        *) die "no prebuilt tarball for $machine; build from source: see the README's Building section" ;;
    esac
}

sha256_of() {
    if have sha256sum; then
        sha256sum "$1" | cut -d' ' -f1
    elif have shasum; then
        shasum -a 256 "$1" | cut -d' ' -f1
    else
        die "sha256sum (or shasum) is required to verify the download"
    fi
}

on_path() {
    case ":$PATH:" in
        *":$1:"*) return 0 ;;
        *) return 1 ;;
    esac
}

add_to_path() { # dir -> append one guarded export line per shell startup file
    dir="$1"
    line="export PATH=\"$dir:\$PATH\""
    for f in "$HOME/.bashrc" "$HOME/.profile"; do
        if ! grep -qF "$line" "$f" 2>/dev/null; then
            printf '\n%s\n' "$line" >> "$f" ||
                die "cannot append to $f"
            note "  appended to $f"
        fi
    done
    case "$(basename "${SHELL:-}")" in
        zsh)
            f="$HOME/.zshrc"
            if ! grep -qF "$line" "$f" 2>/dev/null; then
                printf '\n%s\n' "$line" >> "$f" ||
                    die "cannot append to $f"
                note "  appended to $f"
            fi
            ;;
        fish)
            note "  fish: run once: fish_add_path $dir"
            ;;
    esac
}

# --- Main -------------------------------------------------------------------

[ "$(id -u)" -eq 0 ] &&
    die "don't run this as root; DropTerm installs into the invoking user's home"

have tar || die "tar is required"

version="${DROPTERM_VERSION:-latest}"
if [ "$version" = "latest" ]; then
    version="$(latest_version)"
fi
version="${version#v}"
[ -n "$version" ] || die "empty version"

arch="$(resolve_arch)"
base="https://github.com/$repo/releases/download/v$version"
rawbase="https://raw.githubusercontent.com/$repo/v$version"
archive="dropterm-$version-$arch.tar.gz"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

note "downloading $archive"
download "$base/$archive" "$tmp/$archive" ||
    die "cannot download $base/$archive (is v$version released?)"
download "$base/sha256sums" "$tmp/sha256sums" ||
    die "cannot download the checksums for v$version"
download "$base/sha256sums.sig" "$tmp/sha256sums.sig" ||
    die "v$version ships no signature; it predates signed checksums - install the tarball by hand per the README"
download "$rawbase/keys/allowed_signers" "$tmp/allowed_signers" ||
    die "cannot download keys/allowed_signers from the v$version tag"

have ssh-keygen || die "ssh-keygen (openssh-client) is required to verify the signature"

# Step 1: the checksums file itself, against the release tag's signers.
if ssh-keygen -Y verify -f "$tmp/allowed_signers" -I "$principal" \
    -s "$tmp/sha256sums.sig" -n file < "$tmp/sha256sums"; then
    note "sha256sums signature: good ($principal)"
else
    die "signature check FAILED for v$version's sha256sums; do not install from this source"
fi

# Step 2: the tarball, against the now-verified checksums.
expected="$(sed -n "s/^\([0-9a-f]\{64\}\)  $archive\$/\1/p" "$tmp/sha256sums")"
case "$expected" in
    *[!0-9a-f]*) die "no checksum entry for $archive in the verified sha256sums" ;;
esac
[ "${#expected}" -eq 64 ] || die "no checksum entry for $archive in the verified sha256sums"
actual="$(sha256_of "$tmp/$archive")"
[ "$actual" = "$expected" ] ||
    die "checksum mismatch for $archive: expected $expected, got $actual"
note "checksum: good"

tar -xzf "$tmp/$archive" -C "$tmp"
[ -f "$tmp/usr/bin/dropterm" ] || die "the archive does not contain usr/bin/dropterm"

prefix="${DROPTERM_PREFIX:-$HOME/.local}"
prefix="${prefix%/}"
mkdir -p "$prefix/bin" "$prefix/share" 2>/dev/null || die "cannot create $prefix"
[ -w "$prefix" ] ||
    die "$prefix is not writable; DropTerm never uses sudo, so set DROPTERM_PREFIX to a writable directory"
cp -a "$tmp/usr/." "$prefix/"
note "installed dropterm v$version:"
note "  $prefix/bin/dropterm"
note "  $prefix/share/applications/io.github.l1br3_io.dropterm.desktop"
note "  $prefix/share/metainfo/io.github.l1br3_io.dropterm.metainfo.xml"
note "  $prefix/share/icons/hicolor/scalable/apps/io.github.l1br3_io.dropterm.svg"
note "  $prefix/share/io.github.l1br3_io.dropterm/completions-extended.toml"

if ! on_path "$prefix/bin"; then
    if [ "${DROPTERM_NO_MODIFY_PATH:-0}" = "1" ]; then
        note "warning: $prefix/bin is not on PATH and DROPTERM_NO_MODIFY_PATH=1; add it to your shell startup to type 'dropterm' directly:"
        note "  export PATH=\"$prefix/bin:\$PATH\""
    else
        note "$prefix/bin is not on PATH; adding it to your shell startup files"
        add_to_path "$prefix/bin"
        note "new terminals find 'dropterm' from here on"
    fi
fi

note "next: bind the toggle - COSMIC Settings → Keyboard → Custom Shortcuts,"
note "  Command: dropterm; or run 'dropterm' once and take Configure for me"
note "  in the Keybindings tab (other desktops: README, Setting up the shortcut)"
note "undo: remove the five paths above (see the script header for the exact list)"
