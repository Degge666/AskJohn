#!/bin/bash
# =============================================================================
# AskJohn – src/common.sh (The Sorcery & Dispatcher)
# =============================================================================

# --- VISUAL STYLES ---
export RED='\033[0;31m'; export GREEN='\033[0;32m'; export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'; export CYAN='\033[0;36m'; export WHITE='\033[1;37m'; export NC='\033[0m'

# --- OS DETECTION ---
case "$(uname -s)" in
    Darwin) export OS_TYPE="macos" ;;
    Linux)  export OS_TYPE="linux" ;;
    *)      export OS_TYPE="unknown" ;;
esac

# --- UI: CLEAN HEADER ---
# Clears the screen to keep the "Adventure Card" clean and focused.
print_header() {
    clear
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}       ASKJOHN - $1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# --- THE DISPATCHER (Logic Separation) ---
# This is the core engine that decides WHERE the spell is cast.
invoke_spell() {
    local cmd="$1"

    # 1. Let the user refine the spell via UI-specific input
    local refined_cmd=$(edit_command "$cmd")
    [[ "$refined_cmd" == "ABORT" || -z "$refined_cmd" ]] && return 1

    echo -e "${YELLOW}Casting spell...${NC}\n"

    # 2. Execution Logic: Local vs. Ethereal Bridge (SSH)
    if [[ -z "$SSH_CMD" ]]; then
        # Local execution
        eval "$refined_cmd"
    else
        # Remote execution via established bridge
        $SSH_CMD "$refined_cmd"
    fi

    return $?
}

# --- UI: COMMAND EDITOR ---
# Handles the interactive part of command confirmation.
edit_command() {
    local initial_cmd="$1"
    if [[ "$OS_TYPE" == "macos" ]]; then
        # Use macOS specific popup for a cleaner adventure feel
        local result=$(osascript <<EOT
            tell application "System Events"
                activate
                try
                    set res to display dialog "Finalize your spell:" default answer "$initial_cmd" buttons {"Cancel", "Cast"} default button "Cast" with title "Spell Refiner"
                    return text returned of res
                on error
                    return "ABORT"
                end try
            end tell
EOT
        )
        echo "$result"
    else
        # Fallback for Linux or remote shells
        echo -e "${YELLOW}Refine your spell (Use arrows to edit):${NC}"
        read -e -i "$initial_cmd" -p "> " edited
        echo "$edited"
    fi
}