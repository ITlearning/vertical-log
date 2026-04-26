#!/usr/bin/env bash
#
# CAGL Share-Ready Compile Prototype
# ===================================
# Generates share_ready.mp4 with the CAGL layout
# (2x2 grid centered, 400px top + 400px bottom dead zones)
# to validate that IG/TikTok/YT Shorts UI overlays do
# NOT cover any member content.
#
# Usage:
#   ./scripts/cagl-prototype.sh
#
# Requirements:
#   - ffmpeg (brew install ffmpeg)
#
# Output:
#   scripts/output/share_ready.mp4
#
# Spec reference: design doc Section 12a

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"
SAMPLES_DIR="$SCRIPT_DIR/samples"
FONT="/System/Library/Fonts/Helvetica.ttc"

mkdir -p "$OUTPUT_DIR" "$SAMPLES_DIR"

# Sanity check
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg not installed. Run: brew install ffmpeg"
  exit 1
fi

if [ ! -f "$FONT" ]; then
  echo "WARNING: $FONT not found. Trying fallback..."
  FONT="/System/Library/Fonts/Supplemental/Arial.ttf"
  [ ! -f "$FONT" ] && { echo "ERROR: no usable font found"; exit 1; }
fi

echo "================================================"
echo "  CAGL Share-Ready Compile Prototype"
echo "================================================"
echo "Output canvas: 1080x1920 (9:16)"
echo "Grid:          2x2 centered, 540x560 each cell"
echo "Dead zones:    top 400px + bottom 400px"
echo "Safe zone:     1080x1120 (58% of canvas)"
echo ""

# ------------------------------------------------------------------
# Step 1: Generate 4 sample 9:16 test clips (if not present)
# ------------------------------------------------------------------
if [ ! -f "$SAMPLES_DIR/m1.mp4" ]; then
  echo "[1/3] Generating 4 sample test clips (540x560, 6s each)..."
  declare -a COLORS=("0xFF6B6B" "0x4ECDC4" "0xFFE66D" "0xA8E6CF")
  declare -a LABELS=("M1" "M2" "M3" "M4")

  for i in 0 1 2 3; do
    n=$((i+1))
    ffmpeg -y -loglevel error \
      -f lavfi -i "color=c=${COLORS[$i]}:s=540x560:d=6:r=30" \
      -vf "drawtext=text='${LABELS[$i]}':fontsize=120:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:fontfile=$FONT,drawtext=text='cell %{n}':fontsize=32:fontcolor=white@0.7:x=(w-text_w)/2:y=h-60:fontfile=$FONT" \
      -c:v libx264 -pix_fmt yuv420p -preset ultrafast \
      "$SAMPLES_DIR/m${n}.mp4"
  done
  echo "      -> 4 clips in $SAMPLES_DIR/"
else
  echo "[1/3] Using existing samples in $SAMPLES_DIR/"
  echo "      (delete the dir to regenerate)"
fi

# ------------------------------------------------------------------
# Step 2: Run CAGL compile (xstack + pad + drawtext)
# ------------------------------------------------------------------
echo ""
echo "[2/3] Compiling share_ready.mp4 with CAGL layout..."

ffmpeg -y -loglevel warning \
  -i "$SAMPLES_DIR/m1.mp4" \
  -i "$SAMPLES_DIR/m2.mp4" \
  -i "$SAMPLES_DIR/m3.mp4" \
  -i "$SAMPLES_DIR/m4.mp4" \
  -filter_complex "
    [0:v]scale=540:560,setsar=1[v0];
    [1:v]scale=540:560,setsar=1[v1];
    [2:v]scale=540:560,setsar=1[v2];
    [3:v]scale=540:560,setsar=1[v3];
    [v0][v1][v2][v3]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[grid];
    [grid]pad=1080:1920:0:400:color=#0A0A0A[padded];
    [padded]drawtext=text='vertical-log':fontsize=44:x=(w-text_w)/2:y=180:fontcolor=#DDDDDD:fontfile=$FONT[t1];
    [t1]drawtext=text='2026-04-26':fontsize=32:x=(w-text_w)/2:y=240:fontcolor=#888888:fontfile=$FONT[t2];
    [t2]drawtext=text='vertical-log.app':fontsize=32:x=(w-text_w)/2:y=1690:fontcolor=#888888:fontfile=$FONT[final]
  " \
  -map "[final]" \
  -t 6 \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
  -preset medium -crf 22 \
  -an \
  "$OUTPUT_DIR/share_ready.mp4"

# Probe the output to confirm dimensions
DIMS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUTPUT_DIR/share_ready.mp4")
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUTPUT_DIR/share_ready.mp4")
SIZE=$(stat -f%z "$OUTPUT_DIR/share_ready.mp4" 2>/dev/null || stat -c%s "$OUTPUT_DIR/share_ready.mp4")

echo "      -> $OUTPUT_DIR/share_ready.mp4"
echo "      Dimensions: $DIMS"
echo "      Duration:   ${DURATION}s"
echo "      File size:  $((SIZE/1024)) KB"

# ------------------------------------------------------------------
# Step 3: Verification instructions
# ------------------------------------------------------------------
echo ""
echo "================================================"
echo "  NEXT — Validate IG/TikTok safe zones"
echo "================================================"
echo ""
echo "  1. Preview locally:"
echo "       open $OUTPUT_DIR/share_ready.mp4"
echo ""
echo "  2. AirDrop the file to your iPhone."
echo ""
echo "  3. In IG Reels: tap '+' -> select share_ready.mp4"
echo "     STOP at the editor screen (don't post)."
echo "     Screenshot the editor preview."
echo ""
echo "  4. In screenshot, verify:"
echo "       [v] All 4 'Mn' labels fully visible (NONE cut off)"
echo "       [v] IG profile/music name UI sits in TOP dead zone (~400px)"
echo "       [v] IG caption/like/comment UI sits in BOTTOM dead zone (~400px)"
echo "       [x] If any 'Mn' label is overlapped -> dead zone too small"
echo "       [x] If dead zones look wasteful -> dead zone too big"
echo ""
echo "  5. Repeat on TikTok and YT Shorts (overlay sizes differ)."
echo ""
echo "  6. Report back: which zone is wrong, by how many px."
echo "     We'll adjust the 400px constant in the design doc + this script."
echo ""

# Try to open output if interactive
if [ -t 0 ] && [ -z "${CI:-}" ]; then
  read -r -p "Open share_ready.mp4 now? [y/N] " REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    open "$OUTPUT_DIR/share_ready.mp4"
  fi
fi
