#!/bin/bash
# =============================================================================
# ASKJOHN - THE MAIN GATE (Entry Point)
# =============================================================================
# Description: Central controller for the AskJohn framework.
#              Initializes environment and routes the seeker to the views.

# --- 1. INITIALIZE ENVIRONMENT ---
export BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load common utilities (Colors, Header, etc.)
if [[ -f "$BASE_DIR/src/common.sh" ]]; then
    source "$BASE_DIR/src/common.sh"
else
    # Fallback if common.sh is missing (basic colors)
    RED='\033[0;31m'; GREEN='\033[0;32m'; WHITE='\033[1;37m';
    CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'; BLUE='\033[0;34m'
    print_header() { echo -e "\n=== $1 ==="; }
fi

# Pre-load UI Controllers
[[ -f "$BASE_DIR/src/cracking_ui.sh" ]] && source "$BASE_DIR/src/cracking_ui.sh"
[[ -f "$BASE_DIR/src/wordlist_library_ui.sh" ]] && source "$BASE_DIR/src/wordlist_library_ui.sh"

# --- 2. GLOBAL SETTINGS ---
export SSH_CMD=""

# --- 3. MAIN ADVENTURE LOOP ---
while true; do
    print_header "THE MAIN GATE"

    echo -e "Current Realm: $([[ -z "$SSH_CMD" ]] && echo -e "${GREEN}Local Path${NC}" || echo -e "${YELLOW}Remote Bridge (SSH)${NC}")"
    echo "------------------------------------------------"
    echo -e " 1) ${WHITE}Ask John to solve a Riddle${NC} (Cracking Camp)"
    echo -e " 2) ${WHITE}Ask an Oracle${NC} (Get Hash-Info)"
    echo -e " 3) ${WHITE}Go the Scavenger's Path${NC} (Get Hashes from Source)"
    echo -e " 4) ${WHITE}The Great Library${NC} (Manage Wordlists)"
    echo "------------------------------------------------"
    echo -e " s) ${CYAN}Establish Ethereal Bridge (SSH)${NC}"
    echo -e " q) ${RED}Leave the Realm${NC}"
    echo "------------------------------------------------"
    read -p "Where shall your journey lead? " choice

    case "$choice" in
        1)
            enter_cracking_camp
            ;;
        2)
            # Hier wurde die oracle_ui.sh durch get_hash_info_ui.sh ersetzt
            if [[ -f "$BASE_DIR/src/get_hash_info_ui.sh" ]]; then
                source "$BASE_DIR/src/get_hash_info_ui.sh"
                enter_oracle_chamber
            else
                echo -e "${RED}Error: src/get_hash_info_ui.sh not found!${NC}"
                echo -e "${YELLOW}The Oracle is missing its script...${NC}"
                sleep 2
            fi
            ;;
        3)
            echo -e "${YELLOW}The Scavenger is out in the woods... (Coming soon)${NC}"
            sleep 2
            ;;
        4)
            manage_wordlist_library
            ;;
        s)
            print_header "ETHEREAL BRIDGE"
            read -p "Enter user@host (or leave empty for local): " remote
            if [[ -n "$remote" ]]; then
                export SSH_CMD="ssh -t $remote"
                echo -e "${GREEN}Bridge established!${NC}"
            else
                export SSH_CMD=""
                echo -e "${YELLOW}Bridge collapsed. Working locally.${NC}"
            fi
            sleep 1
            ;;
        q)
            echo -e "${BLUE}May your secrets remain safe. Farewell!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown path, traveler.${NC}"
            sleep 1
            ;;
    esac
done