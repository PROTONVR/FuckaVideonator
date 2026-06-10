#!/usr/bin/env sh
set -eu

SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
VESTROYER="$SOURCE_DIR/vestroyer"
WORKDIR=$(mktemp -d)
INPUT="$WORKDIR/input.mp4"
FAILED=0
PASSED=0

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "error: ffmpeg is required for preset tests" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required for preset tests" >&2
  exit 1
fi

chmod +x "$VESTROYER"

echo "creating short test clip..."
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "testsrc=size=1280x720:rate=30" \
  -f lavfi -i "sine=frequency=440:duration=2" \
  -shortest -t 2 -pix_fmt yuv420p "$INPUT"

PRESETS="4k 1080 720 480 360 240 144 96 wtf"
APRESETS="clean normal low crunchy phone destroyed"

echo "testing presets..."
for preset in $PRESETS; do
  output="$WORKDIR/output_${preset}.mp4"
  printf '  %-5s ... ' "$preset"
  if "$VESTROYER" "$INPUT" -preset "$preset" "$output" >/dev/null 2>&1; then
    if [ -s "$output" ]; then
      echo "ok"
      PASSED=$((PASSED + 1))
    else
      echo "fail (empty output)"
      FAILED=$((FAILED + 1))
    fi
  else
    echo "fail"
    FAILED=$((FAILED + 1))
  fi
done

echo "testing audio presets..."
for apreset in $APRESETS; do
  output="$WORKDIR/audio_${apreset}.mp4"
  printf '  %-9s ... ' "$apreset"
  if "$VESTROYER" "$INPUT" -preset 240 -apreset "$apreset" "$output" >/dev/null 2>&1; then
    if [ -s "$output" ]; then
      echo "ok"
      PASSED=$((PASSED + 1))
    else
      echo "fail (empty output)"
      FAILED=$((FAILED + 1))
    fi
  else
    echo "fail"
    FAILED=$((FAILED + 1))
  fi
done

echo "testing preset aliases..."
for alias in uhd fhd hd 64x36; do
  output="$WORKDIR/alias_${alias}.mp4"
  printf '  %-6s ... ' "$alias"
  if "$VESTROYER" "$INPUT" -preset "$alias" "$output" >/dev/null 2>&1; then
    echo "ok"
    PASSED=$((PASSED + 1))
  else
    echo "fail"
    FAILED=$((FAILED + 1))
  fi
done

echo
echo "passed: $PASSED"
echo "failed: $FAILED"

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
