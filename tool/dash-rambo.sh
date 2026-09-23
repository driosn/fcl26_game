#!/usr/bin/env bash
# Launch wrapper for SteamOS Gaming Mode / gamescope.
set -euo pipefail
cd "$(dirname "$0")"
export GDK_BACKEND="${GDK_BACKEND:-x11}"
export DASH_RAMBO_FULLSCREEN="${DASH_RAMBO_FULLSCREEN:-1}"
# So the game treats this launch as a Deck even if Steam forgot the env var.
export SteamDeck="${SteamDeck:-1}"
exec ./fcl_26_game "$@"
