#!/usr/bin/env bash
#
# inspect-images.sh — metadata backstop for committed screenshots.
#
# Screenshots are the highest-risk surface: EXIF/embedded metadata can carry usernames, software
# versions, timestamps, GPS, and thumbnails. Primary redaction is at capture time (clean prompt +
# clean browser profile); this is the automated backstop.
#
# Usage:
#   bash scripts/inspect-images.sh [path]            # report metadata (default path: .)
#   bash scripts/inspect-images.sh --strip [path]    # strip all metadata in place
#
# Exit: 0 = no concerning metadata (or stripped)   1 = metadata found / tool missing
set -uo pipefail

STRIP=0
if [ "${1:-}" = "--strip" ]; then STRIP=1; shift; fi
TARGET="${1:-.}"

mapfile -t IMAGES < <(find "$TARGET" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
                      -o -iname '*.gif' -o -iname '*.tiff' -o -iname '*.webp' \) -not -path '*/.git/*' 2>/dev/null)

if [ "${#IMAGES[@]}" -eq 0 ]; then
  echo "No images found under: $TARGET"; exit 0
fi

if ! command -v exiftool >/dev/null 2>&1; then
  echo "WARNING: exiftool not installed — cannot verify image metadata."
  echo "  Debian/Ubuntu: sudo apt-get install -y libimage-exiftool-perl"
  exit 1
fi

# Tags that are benign for a screenshot (geometry / format only).
BENIGN='^(ExifTool Version|File Name|Directory|File Size|File Modification|File Access|File Inode|File Permissions|File Type|File Type Extension|MIME Type|Image Width|Image Height|Image Size|Megapixels|Bit Depth|Color Type|Compression|Filter|Interlace|Background Color|Pixels Per Unit|SRGB Rendering)'

found=0
for img in "${IMAGES[@]}"; do
  if [ "$STRIP" -eq 1 ]; then
    exiftool -q -overwrite_original -all= "$img" >/dev/null 2>&1 && echo "stripped: $img"
    continue
  fi
  extra=$(exiftool "$img" 2>/dev/null | grep -vE "$BENIGN" || true)
  if [ -n "$extra" ]; then
    found=1
    echo "[REVIEW] metadata present in: $img"
    sed 's/^/    /' <<<"$extra"
  fi
done

if [ "$STRIP" -eq 1 ]; then echo "IMAGE METADATA STRIPPED"; exit 0; fi
if [ "$found" -eq 0 ]; then echo "IMAGES CLEAN"; exit 0; else
  echo "IMAGE METADATA REVIEW REQUIRED (run with --strip to remove)"; exit 1
fi
