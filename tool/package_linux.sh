#!/usr/bin/env bash
# Native Linux bundle for Steam Deck (non-Steam game).
# Must run on Linux: this Mac cannot emit a useful .so.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "package_linux.sh has to run on Linux (SteamOS Desktop Mode, another box, or Docker)." >&2
  echo "This host is $(uname -s)." >&2
  exit 1
fi

flutter build linux --release

dest="${1:-"$root/build/dash-rambo-linux"}"
rm -rf "$dest"
mkdir -p "$dest"
cp -R "$root/build/linux/x64/release/bundle/." "$dest/"
cp "$root/tool/dash-rambo.sh" "$dest/dash-rambo.sh"
printf '1.0.1\n' > "$dest/BUILD.txt"
chmod +x "$dest/dash-rambo.sh" "$dest/fcl_26_game"

echo "Bundle: $dest"
echo "Add that folder's dash-rambo.sh as a non-Steam game. See docs/steam-deck.md."
