#!/usr/bin/env bash
# Remove xclip-shim and restore the original xclip (if one was backed up).
set -euo pipefail
PREFIX="${PREFIX:-/usr/local}"

if [ -f "$PREFIX/bin/xclip.shim-bak" ]; then
  sudo mv "$PREFIX/bin/xclip.shim-bak" "$PREFIX/bin/xclip"
  echo "✓ restored original xclip"
else
  sudo rm -f "$PREFIX/bin/xclip"
  if [ -x /usr/bin/xclip ]; then
    echo "✓ shim removed; /usr/bin/xclip is back in effect"
  else
    echo "✓ shim removed (no system xclip was present)"
  fi
fi
