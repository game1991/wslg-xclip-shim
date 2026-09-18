#!/usr/bin/env bash
# Install xclip-shim: enable AI CLI image paste on WSL2 distros with broken interop.
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"

echo "==> xclip-shim installer"

# 1. environment checks
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  echo "✗ not running inside WSL, nothing to do"; exit 1
fi
if [ ! -S /mnt/wslg/runtime-dir/wayland-0 ]; then
  echo "✗ WSLg Wayland socket not found at /mnt/wslg/runtime-dir/wayland-0"
  echo "  (WSLg requires WSL2 on Windows 11, or Windows 10 with WSLg-enabled WSL)"
  exit 1
fi

# 2. dependencies: wl-paste (wl-clipboard), convert (ImageMagick)
need=()
command -v wl-paste >/dev/null 2>&1 || need+=(wl-clipboard)
command -v convert >/dev/null 2>&1 || need+=(imagemagick)
if [ ${#need[@]} -gt 0 ]; then
  echo "==> missing dependencies: ${need[*]}"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y "${need[@]}"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "${need[@]}"
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y "${need[@]}"
  else
    echo "✗ please install manually: ${need[*]}"; exit 1
  fi
fi

# 3. install the shim (shadowing /usr/bin/xclip via PATH order)
if [ -x "$PREFIX/bin/xclip" ] && ! cmp -s xclip "$PREFIX/bin/xclip"; then
  echo "==> backing up existing $PREFIX/bin/xclip to $PREFIX/bin/xclip.shim-bak"
  cp "$PREFIX/bin/xclip" "$PREFIX/bin/xclip.shim-bak"
fi
sudo install -m 755 xclip "$PREFIX/bin/xclip"
echo "✓ installed $PREFIX/bin/xclip"

# 4. self-test: probe the clipboard capability path an AI CLI would use
echo "==> self-test (put something on the Windows clipboard first)"
if "$PREFIX/bin/xclip" -selection clipboard -t TARGETS -o 2>/dev/null | grep -q 'image/'; then
  echo "✓ clipboard image detected: $("$PREFIX/bin/xclip" -selection clipboard -t TARGETS -o | tr '\n' ' ')"
  echo "  image paste should now work — try Alt+V in your AI CLI"
else
  echo "✓ shim installed. no image on clipboard right now (text is passed through to real xclip)."
  echo "  Take a screenshot (Win+Shift+S), then try Alt+V in your AI CLI."
fi

echo
echo "Done. To uninstall: ./uninstall.sh"
