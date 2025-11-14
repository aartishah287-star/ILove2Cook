#!/usr/bin/env bash
# capture_demo.sh — Capture successive screenshots from a connected Android device/emulator
# Produces demo.gif in the repository root using adb + ffmpeg
# Prereqs: adb (Android platform-tools), ffmpeg
# Usage:
# 1) Start your emulator or connect your Android device and install/run the app.
# 2) From repo root: ./scripts/capture_demo.sh --frames 6 --delay 1

set -euo pipefail
FRAMES=6
DELAY=1
OUTDIR=".tmp_screenshots"
OUTGIF="demo.gif"
QUIET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --frames) FRAMES="$2"; shift 2 ;;
    --delay) DELAY="$2"; shift 2 ;;
    --out) OUTGIF="$2"; shift 2 ;;
    --quiet) QUIET=true; shift ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--frames N] [--delay S] [--out file.gif]

--frames  Number of screenshots to capture (default: 6)
--delay   Seconds to wait between screenshots (default: 1)
--out     Output gif filename (default: demo.gif)
--quiet   Suppress some messages

Requirements: adb, ffmpeg
Workflow:
  - Ensure the app is running on the connected device/emulator
  - Run this script to capture a short sequence and produce a GIF
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

function log() { if [ "$QUIET" = false ]; then echo "[capture_demo] $*"; fi }

if ! command -v adb >/dev/null 2>&1; then
  echo "Error: adb not found. Install Android platform-tools and ensure 'adb' is on PATH." >&2
  exit 2
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg not found. Install ffmpeg to build the GIF." >&2
  exit 3
fi

log "Checking connected devices..."
DEVICES=$(adb devices | sed -n '2,$p' | awk '{print $1}')
if [ -z "${DEVICES//\n/}" ]; then
  echo "No device/emulator found. Start an emulator (Android Studio) or connect a device." >&2
  exit 4
fi
log "Devices found:"
adb devices | sed -n '2,200p' | sed '/^$/d' | awk '{print " - "$1" ("$2")"}' | sed 's/\t/ /g'

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

log "Capturing $FRAMES frames with $DELAY sec delay..."
for i in $(seq 0 $((FRAMES-1))); do
  idx=$(printf "%02d" "$i")
  file="$OUTDIR/shot${idx}.png"
  log "Capturing frame $i -> $file"

  # Use adb exec-out to write a PNG directly to stdout and redirect to file
  adb exec-out screencap -p > "$file"
  sleep "$DELAY"
done

log "Generating GIF: $OUTGIF (this may take a moment)"
# generate palette then gif for better colors
ffmpeg -y -i "$OUTDIR/shot%02d.png" -vf palettegen "$OUTDIR/palette.png"
ffmpeg -y -framerate 2 -i "$OUTDIR/shot%02d.png" -i "$OUTDIR/palette.png" -lavfi paletteuse -loop 0 "$OUTGIF"

log "Cleaning temporary files"
rm -rf "$OUTDIR"

log "Done — created $OUTGIF"
exit 0
