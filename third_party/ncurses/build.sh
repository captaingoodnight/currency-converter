#!/usr/bin/env bash
# Downloads and builds ncurses for the GNAT Pro mingw toolchain, installing
# it under third_party/ncurses/install/ for ada_demo.gpr to link against.
set -euo pipefail

# A fresh MSYS2 bash process resets its *entire* inherited environment on
# startup - not just TMP/TEMP, but any custom exported variable, and this
# happens whether it's launched as a new process or reached via this script's
# own `exec` self-replacement. So nothing passed via the environment survives
# the re-exec below; only argv does. Capture TMP now (before re-exec, where
# it's still reliably set) and thread it through as a leading marker argument
# instead, parsed back out on the other side.
case "${1:-}" in
    --internal-win-tmp=*)
        WIN_TMP="${1#--internal-win-tmp=}"
        shift
        ;;
    *)
        WIN_TMP="${TMP:-${TEMP:-}}"
        if [ -z "$WIN_TMP" ]; then
            echo "error: neither TMP nor TEMP is set in the environment." >&2
            exit 1
        fi

        # Re-exec under MSYS2's own bash/coreutils if available. Running make
        # (which must be MSYS2's, since that's the only make.exe on this
        # machine) while cat/gawk/sh resolve to Git Bash's *different*
        # bundled MSYS runtime corrupts recipe output silently: file
        # handles/redirects passed between two distinct msys-2.0.dll builds
        # don't marshal correctly, producing truncated generated headers
        # with no error. One consistent runtime avoids this. GNAT's mingw
        # gcc also needs a working TMP/TEMP for its own temporary object
        # files, hence threading WIN_TMP through too.
        MSYS2_BASH="/c/msys64/usr/bin/bash.exe"
        if [ -x "$MSYS2_BASH" ] && [ "${NCURSES_BUILD_REEXEC:-}" != "1" ]; then
            export NCURSES_BUILD_REEXEC=1
            export PATH="/c/msys64/usr/bin:$PATH"
            exec "$MSYS2_BASH" "$0" "--internal-win-tmp=$WIN_TMP" "$@"
        fi
        ;;
esac
export TMP="$WIN_TMP"
export TEMP="$WIN_TMP"

VERSION="6.6"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="$SCRIPT_DIR/install"
# Built outside the workspace tree: on Windows, VS Code's file watcher (and
# extensions that index headers) repeatedly opens files this rapid autotools
# build rewrites, racing our shell's writes into "Device or resource busy"
# errors. Only the final `make install` output needs to live in-repo.
SRC_ROOT="/tmp/ncurses-build-ada-demo"
SRC_DIR="$SRC_ROOT/ncurses-$VERSION"
TARBALL="$SCRIPT_DIR/ncurses-$VERSION.tar.gz"
URL="https://invisible-island.net/archives/ncurses/ncurses-$VERSION.tar.gz"

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

if [ "$FORCE" = 0 ] && [ -f "$PREFIX/lib/libncurses.a" ] && [ -f "$PREFIX/include/ncurses.h" ]; then
    echo "ncurses already built at $PREFIX (pass --force to rebuild)"
    exit 0
fi

if ! command -v make >/dev/null 2>&1; then
    echo "error: 'make' not found on PATH." >&2
    echo "Install a Windows make (e.g. an ezwinports/GnuWin32 build), add it to PATH, and re-run this script." >&2
    exit 1
fi

CC="$(command -v gcc || true)"
if [ -z "$CC" ]; then
    echo "error: no 'gcc' found on PATH (expected the GNAT Pro mingw gcc)." >&2
    exit 1
fi
HOST="$("$CC" -dumpmachine)"
echo "Using CC=$CC (host triple: $HOST)"

if [ ! -f "$TARBALL" ]; then
    echo "Downloading ncurses $VERSION..."
    curl -fsSL -o "$TARBALL" "$URL"
fi

rm -rf "$SRC_DIR"
mkdir -p "$SRC_ROOT"
echo "Extracting..."
tar -xzf "$TARBALL" -C "$SRC_ROOT"

cd "$SRC_DIR"
echo "Configuring..."
./configure \
    CC="$CC" \
    --host="$HOST" \
    --prefix="$PREFIX" \
    --enable-term-driver \
    --without-shared \
    --with-normal \
    --without-ada \
    --without-progs \
    --without-tests \
    --without-manpages \
    --without-cxx \
    --without-cxx-binding \
    --disable-widec

# MSYS2's make.exe additionally blanks TMP/TEMP before running recipe shells
# specifically (on top of the shell-level issue worked around above), so it
# still needs to be forced onto each make invocation as a command-line var.
echo "Building..."
# Serial build: the generated include/Makefile has header-generation rules
# that race on Windows' exclusive file locking under -j.
make TMP="$WIN_TMP" TEMP="$WIN_TMP"

echo "Installing to $PREFIX..."
make install TMP="$WIN_TMP" TEMP="$WIN_TMP"

if [ ! -f "$PREFIX/lib/libncurses.a" ]; then
    echo "error: build finished but $PREFIX/lib/libncurses.a was not produced" >&2
    exit 1
fi

echo "ncurses built and installed to $PREFIX"
