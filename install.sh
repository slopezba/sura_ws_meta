#!/usr/bin/env bash
set -euo pipefail

SURA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SURA_BIN="$SURA_HOME/bin/sura"
TARGET="/usr/local/bin/sura"

echo "============================================================"
echo " SURA Installer"
echo "============================================================"
echo
echo "Workspace:"
echo "  $SURA_HOME"
echo

if [ ! -f "$SURA_HOME/docker-compose.yml" ]; then
  echo "Error: docker-compose.yml was not found in:"
  echo "  $SURA_HOME"
  exit 1
fi

if [ ! -f "$SURA_BIN" ]; then
  echo "Error: SURA command was not found in:"
  echo "  $SURA_BIN"
  exit 1
fi

chmod +x "$SURA_BIN"
mkdir -p "$SURA_HOME/.sura"

echo "Creating global command:"
echo "  $TARGET -> $SURA_BIN"
echo

sudo ln -sf "$SURA_BIN" "$TARGET"

echo "Installation completed successfully."
echo
echo "You can now run SURA from any directory:"
echo "  sura setup"
echo "  sura start"
echo "  sura shell"
echo "  sura stop"
echo
