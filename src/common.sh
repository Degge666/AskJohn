#!/usr/bin/env bash
# =============================================================================
# AskJohn – common.sh
# Shared helpers, colors and config loading
# =============================================================================

set -uo pipefail

# ── ANSI Color Codes (müssen vor allen anderen Zugriffen definiert sein) ─────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'     # ← das fehlte oder war nicht erreichbar
PURPLE='\033[0;35m'
NC='\033[0m'

# ── Central config file ─────────────────────────────────────────────────────
CONFIG_FILE="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/../config.sh"

# ── Helper: Load config safely ──────────────────────────────────────────────
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        echo -e "${GREEN}Configuration loaded: $CONFIG_FILE${NC}"
    else
        echo -e "${RED}Error: config.sh not found at $CONFIG_FILE${NC}"
        echo "Run setup-john-env.sh first"
        exit 1
    fi
}

# ── Print header (Pi-Control style) ─────────────────────────────────────────
print_header() {
    local title="$1"
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}       ASKJOHN - $title${NC}"
    echo -e "${CYAN}================================================${NC}"
}

# ── Update WORDLISTS in config.sh ───────────────────────────────────────────
update_wordlists_in_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}config.sh missing – cannot update${NC}"
        return 1
    fi

    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" 2>/dev/null || true

    {
        grep -v '^WORDLISTS=' "$CONFIG_FILE" || true
        echo ""
        echo "# Wordlists – updated $(date '+%Y-%m-%d %H:%M:%S')"
        echo "declare -a WORDLISTS=("
        for p in "${WORDLISTS[@]}"; do
            printf "    %q\n" "$p"
        done
        echo ")"
    } > "${CONFIG_FILE}.tmp"

    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "${GREEN}config.sh updated – ${#WORDLISTS[@]} wordlists total${NC}"
}
