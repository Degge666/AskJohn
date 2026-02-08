#!/usr/bin/env bash
# =============================================================================
# AskJohn – setup-john-env.sh
# Phase 1: OS detection, John location & config generation
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" || { echo "Failed to load common.sh"; exit 1; }

print_header "Environment Setup (Phase 1)"

# ── OS detection ────────────────────────────────────────────────────────────
OS_FAMILY="Unknown"
HB_PREFIX=""

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_FAMILY="macOS"
    HB_PREFIX="/opt/homebrew"
    [[ ! -d "$HB_PREFIX" ]] && HB_PREFIX="/usr/local"
elif [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "linux-musl"* ]]; then
    OS_FAMILY="Linux"
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo -e "→ Operating System:   ${GREEN}${OS_FAMILY}${NC}"

# ── Locate john ─────────────────────────────────────────────────────────────
JOHN_BIN=$(command -v john 2>/dev/null)

if [[ -z "$JOHN_BIN" && "$OS_FAMILY" == "macOS" ]]; then
    [[ -x "${HB_PREFIX}/bin/john" ]] && JOHN_BIN="${HB_PREFIX}/bin/john"
fi

if [[ -z "$JOHN_BIN" && "$OS_FAMILY" == "Linux" ]]; then
    for p in /usr/bin/john /usr/sbin/john /usr/local/bin/john; do
        [[ -x "$p" ]] && JOHN_BIN="$p" && break
    done
fi

if [[ -n "$JOHN_BIN" && -x "$JOHN_BIN" ]]; then
    echo -e "→ John path:          ${GREEN}${JOHN_BIN}${NC}"
    VERSION=$("$JOHN_BIN" 2>&1 | head -n1 | grep -i -E 'john|ripper|version')
    [[ -n "$VERSION" ]] && echo -e "→ Version:            ${GREEN}${VERSION}${NC}"
else
    echo -e "${RED}John not found${NC}"
    exit 1
fi

# ── Write / update config.sh ────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${YELLOW}Creating config.sh ...${NC}"
    cat > "$CONFIG_FILE" << EOF
#!/usr/bin/env bash
# AskJohn - Personal Configuration (DO NOT COMMIT)
# Generated $(date '+%Y-%m-%d %H:%M:%S')

OS_FAMILY="$OS_FAMILY"
JOHN_BIN="$JOHN_BIN"

# Add more later ...
EOF
    echo -e "${GREEN}Created: $CONFIG_FILE${NC}"
else
    echo -e "${YELLOW}config.sh already exists – not overwriting${NC}"
fi

echo -e "${GREEN}Setup finished${NC}"