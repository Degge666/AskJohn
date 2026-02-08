#!/usr/bin/env bash
# AskJohn v0.1 – OS-Detection + Config + John-Prüfung
set -uo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'

echo -e "${GREEN}AskJohn v0.1 starting ...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="$PROJECT_ROOT/config.sh"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo -e "${GREEN}→ Config geladen${NC}"
else
    source "$PROJECT_ROOT/examples/config.example.sh"
    echo -e "${YELLOW}→ Nur Beispiel-Config${NC}"
fi

# OS Detection
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_FAMILY="macOS"
    HB_PREFIX="/opt/homebrew"
    [[ ! -d "$HB_PREFIX" ]] && HB_PREFIX="/usr/local"
else
    OS_FAMILY="Linux"   # vorerst – Windows später
fi

echo "OS → $OS_FAMILY"

# John finden
if [[ -z "${JOHN_BIN:-}" ]]; then
    JOHN_BIN=$(command -v john 2>/dev/null || echo "${HB_PREFIX}/bin/john" 2>/dev/null)
fi

if [[ -x "$JOHN_BIN" ]]; then
    echo -e "${GREEN}John OK: $JOHN_BIN${NC}"
    $JOHN_BIN --version | head -n1
else
    echo -e "${RED}John nicht gefunden${NC}"
    exit 1
fi

echo "Fertig. Schreibe 'weiter' wenn ok."
while true; do read -r x; [[ "$x" == "weiter" ]] && exit 0; done
