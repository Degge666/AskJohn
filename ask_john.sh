#!/bin/bash
# =============================================================================
# ASKJOHN - THE MAIN GATE (Entry Point)
# =============================================================================

# --- 1. INITIALIZE ENVIRONMENT ---
export BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load global configuration
if [[ -f "$BASE_DIR/config.sh" ]]; then
    source "$BASE_DIR/config.sh"
    export JOHN_PATH="${JOHN_BIN:-john}"
else
    export JOHN_PATH="john"
fi

# Load common utilities
[[ -f "$BASE_DIR/src/common.sh" ]] && source "$BASE_DIR/src/common.sh"

# --- 2. GLOBAL SETTINGS ---
export SSH_HOST=""

# --- 3. MAIN ADVENTURE LOOP ---
while true; do
    print_header "THE MAIN GATE"

    # Status Display
    if [[ -n "$SSH_HOST" ]]; then
        echo -e "Current Realm: ${YELLOW}Remote Bridge ($SSH_HOST)${NC}"
    else
        echo -e "Current Realm: ${GREEN}Local Path${NC}"
    fi

    echo "------------------------------------------------"
    echo -e " 1) ${CYAN}Give John a Riddle${NC} (Hash Management)"
    echo -e " 2) Ask John to solve a Riddle (Cracking Camp)"
    echo -e " 3) The Great Library (Manage Wordlists)"
    echo -e " 4) Ask an Oracle (General Hash-Info)"
    echo "------------------------------------------------"
    echo -e " s) Establish Ethereal Bridge (SSH)"
    echo -e " q) Leave the Realm"
    echo "------------------------------------------------"
    read -p "Where shall your journey lead? " main_choice

    case "$main_choice" in
        1)
            # Hash Management (Add, Paste, Scavenge)
            source "$BASE_DIR/src/cracking_ui.sh"
            add_new_riddle
            ;;
        2)
            # The Cracking Table (Status, Solve, Rules)
            source "$BASE_DIR/src/cracking_ui.sh"
            enter_cracking_camp
            ;;
        3)
            # Wordlists
            if [[ -f "$BASE_DIR/src/library_ui.sh" ]]; then
                source "$BASE_DIR/src/library_ui.sh"
                manage_library
            else
                echo -e "${RED}Library not found.${NC}"
                sleep 1
            fi
            ;;
        4)
            # General Oracle
            if [[ -f "$BASE_DIR/src/get_hash_info_ui.sh" ]]; then
                source "$BASE_DIR/src/get_hash_info_ui.sh"
                enter_oracle_chamber
            else
                echo -e "${RED}Oracle chamber is locked.${NC}"
                sleep 1
            fi
            ;;
        s)
            print_header "ETHEREAL BRIDGE"
            read -p "Enter user@host (leave empty for local): " remote
            export SSH_HOST="$remote"
            [[ -n "$SSH_HOST" ]] && echo -e "${GREEN}Bridge established!${NC}" || echo -e "${YELLOW}Bridge collapsed.${NC}"
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