#!/usr/bin/env bash
# =============================================================================
# ASKJOHN - Main Entry Point
# =============================================================================

# Get the directory of this script
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PROJECT_ROOT/src"

# Load shared helpers (colors, headers)
source "$SRC_DIR/common.sh" || { echo "Error: src/common.sh not found"; exit 1; }

# Load local config
if [[ -f "$PROJECT_ROOT/config.sh" ]]; then
    source "$PROJECT_ROOT/config.sh"
else
    echo -e "${YELLOW}Warning: config.sh not found. Running setup...${NC}"
    bash "$SRC_DIR/setup-john-env.sh"
    source "$PROJECT_ROOT/config.sh"
fi

# Main Menu Function
show_main_menu() {
    print_header "MAIN MENU"
    echo -e "System: ${GREEN}$OS_FAMILY${NC} | John: ${GREEN}$JOHN_BIN${NC}"
    echo "------------------------------------------------"
    echo " 1) Wordlist Management (add/download)"
    echo " 2) Get Hashes (Extract from ZIP/RAR/System)"
    echo " 3) Ask John (Cracking Mode)"
    echo " 4) Get Hash-Info (Identify Hash Type)"
    echo " q) Exit"
    echo "------------------------------------------------"
    read -p "Select an option: " choice

    case "$choice" in
        1)
            bash "$SRC_DIR/add_wordlists.sh"
            ;;
        2)
            echo -e "${YELLOW}Module 'Get Hashes' coming soon...${NC}"
            sleep 2
            ;;
        3)
            echo -e "${YELLOW}Module 'Cracking' coming soon...${NC}"
            sleep 2
            ;;
        4)
            echo -e "${YELLOW}Module 'Hash-ID' coming soon...${NC}"
            sleep 2
            ;;
        q|Q)
            echo "Exiting AskJohn. Happy cracking!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            sleep 1
            ;;
    esac
}

# Loop the menu
while true; do
    show_main_menu
done
