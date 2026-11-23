#!/usr/bin/env bash
# Builds the Clip add-on's FFmpeg for one target.
#   TARGET=linux-x64|android-arm64-v8a|android-armeabi-v7a|android-x86_64|windows-x64|macos-arm64|macos-x64
#   ANDROID_NDK_HOME must be set for android-* targets.
# Output: add-on/clip/bin/$TARGET/ffmpeg[.exe]
#
# The flag set is in configure-flags.txt: LGPL only, no TLS (https is handled
# by the app's loopback proxy), stream copy / remux only, no encoders.
set -euo pipefail
: "${TARGET:?set TARGET}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/../bin/$TARGET"
TAG="$(cat "$HERE/FFMPEG_TAG")"
WORK="${WORK:-$(mktemp -d)}"
mkdir -p "$OUT"

git clone --depth 1 --branch "$TAG" https://github.com/FFmpeg/FFmpeg.git "$WORK/ffmpeg"
cd "$WORK/ffmpeg"
mapfile -t FLAGS < <(grep -v '^#' "$HERE/configure-flags.txt" | grep -v '^$')

EXTRA=()
EXE=ffmpeg
case "$TARGET" in
  linux-x64) ;;
  macos-arm64) EXTRA+=(--arch=arm64 --extra-cflags="-arch arm64" --extra-ldflags="-arch arm64") ;;
  macos-x64)   EXTRA+=(--arch=x86_64) ;;
  windows-x64)
    EXE=ffmpeg.exe
    EXTRA+=(--arch=x86_64 --target-os=mingw32 --cross-prefix=x86_64-w64-mingw32- --enable-cross-compile --extra-ldflags="-static") ;;
  android-*)
    : "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME}"
    API=24
    TC="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
    case "$TARGET" in
      android-arm64-v8a)   ARCH=aarch64; TRIPLE=aarch64-linux-android ;;
      android-armeabi-v7a) ARCH=arm;     TRIPLE=armv7a-linux-androideabi ;;
      android-x86_64)      ARCH=x86_64;  TRIPLE=x86_64-linux-android ;;
    esac
    EXTRA+=(--enable-cross-compile --target-os=android --arch="$ARCH"
      --cc="$TC/bin/${TRIPLE}${API}-clang" --cxx="$TC/bin/${TRIPLE}${API}-clang++"
      --ar="$TC/bin/llvm-ar" --ranlib="$TC/bin/llvm-ranlib" --strip="$TC/bin/llvm-strip" --nm="$TC/bin/llvm-nm"
      --sysroot="$TC/sysroot" --enable-pic
      --extra-cflags="-fPIE" --extra-ldflags="-pie -Wl,-z,max-page-size=16384") ;;
  *) echo "unknown TARGET $TARGET" >&2; exit 1 ;;
esac

./configure "${FLAGS[@]}" "${EXTRA[@]}"
make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)" "$EXE"
cp "$EXE" "$OUT/$EXE"
case "$TARGET" in
  android-*) "$TC/bin/llvm-strip" "$OUT/$EXE" ;;
  windows-x64) x86_64-w64-mingw32-strip "$OUT/$EXE" ;;
  *) strip "$OUT/$EXE" || true ;;
esac
chmod 755 "$OUT/$EXE"
ls -la "$OUT/$EXE"
