#!/usr/bin/env bash
# ==============================================================================
# AskJohn - Phase 1: OS Detection, John Location & Config Generation
# ==============================================================================

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}AskJohn – Environment Setup (Phase 1)${NC}"
echo "──────────────────────────────────────"

# ── 1. Detect operating system ──────────────────────────────────────────────
OS_FAMILY="Unknown"

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_FAMILY="macOS"
    HB_PREFIX="/opt/homebrew"
    [[ ! -d "$HB_PREFIX" ]] && HB_PREFIX="/usr/local"  # Intel fallback
elif [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "linux-musl"* ]]; then
    OS_FAMILY="Linux"
else
    echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
    exit 1
fi

echo -e "→ Operating System:   ${GREEN}${OS_FAMILY}${NC}"

# ── 2. Locate John the Ripper binary ────────────────────────────────────────
JOHN_BIN=""

# Priority 1: Found in current PATH
JOHN_BIN=$(command -v john 2>/dev/null)

# Priority 2: macOS Homebrew Jumbo default path
if [[ -z "$JOHN_BIN" && "$OS_FAMILY" == "macOS" && -n "$HB_PREFIX" ]]; then
    candidate="${HB_PREFIX}/bin/john"
    [[ -x "$candidate" ]] && JOHN_BIN="$candidate"
fi

# Priority 3: Common Linux paths (in case PATH is altered)
if [[ -z "$JOHN_BIN" && "$OS_FAMILY" == "Linux" ]]; then
    for p in /usr/bin/john /usr/sbin/john /usr/local/bin/john; do
        [[ -x "$p" ]] && JOHN_BIN="$p" && break
    done
fi

# ── 3. Check result and extract version ─────────────────────────────────────
if [[ -n "$JOHN_BIN" && -x "$JOHN_BIN" ]]; then
    echo -e "→ John binary path:   ${GREEN}${JOHN_BIN}${NC}"

    # Try to extract version (John often outputs to stderr)
    VERSION_STR=$("$JOHN_BIN" 2>&1 | head -n 1 | grep -i -E 'john|ripper|version' | sed 's/^[[:space:]]*//')

    if [[ -n "$VERSION_STR" ]]; then
        echo -e "→ Version:            ${GREEN}${VERSION_STR}${NC}"
    else
        echo -e "→ Version:            ${YELLOW}could not be determined${NC}"
    fi
else
    echo -e "${RED}→ John the Ripper not found or not executable${NC}"
    if [[ "$OS_FAMILY" == "macOS" ]]; then
        echo "  → Recommended: brew install john-jumbo"
    elif [[ "$OS_FAMILY" == "Linux" ]]; then
        echo "  → Recommended: sudo apt install john"
    fi
    exit 1
fi

# ── 4. Generate or update config file (ignored by Git) ──────────────────────
CONFIG_FILE="../config.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${YELLOW}→ Creating config.sh (ignored by .gitignore)${NC}"

    cat > "$CONFIG_FILE" << EOF
#!/usr/bin/env bash
# =============================================================================
# AskJohn - Personal Configuration File
# NEVER commit this file to Git!
# =============================================================================

# Generated automatically on $(date '+%Y-%m-%d %H:%M:%S')

OS_FAMILY="$OS_FAMILY"
JOHN_BIN="$JOHN_BIN"

# Add more paths / settings here later if needed
# WORDLIST_DEFAULT="\$HOME/wordlists/rockyou.txt"
# ZIP2JOHN_BIN="\${JOHN_BIN%/*}/zip2john"

# ── End of configuration ──
EOF

    echo -e "→ config.sh created: $(realpath "$CONFIG_FILE")"
else
    echo -e "${YELLOW}→ config.sh already exists – not overwriting${NC}"
    echo "  (Delete the file manually if you want to force re-detection)"
fi

# ── 5. Final summary ────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Setup completed${NC}"
echo "  • OS_FAMILY     = $OS_FAMILY"
echo "  • JOHN_BIN      = $JOHN_BIN"
echo "  • Configuration = $CONFIG_FILE"
echo ""
echo "Next step: source ../config.sh  (or source it in askjohn.sh)"