#!/usr/bin/env bash
# =============================================================================
# AskJohn – add_wordlists.sh
# Wordlist management - Returns to menu after input
# =============================================================================

# Load common header (colors + print_header)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" || exit 1

# Path to the config file
CONFIG_FILE="$SCRIPT_DIR/../config.sh"

# Initialize local array to prevent "unbound variable" errors
declare -a WORDLISTS=()

# 1. Load existing config if available
if [[ -f "$CONFIG_FILE" ]]; then
    set +u
    source "$CONFIG_FILE"
    set -u
fi

# 2. Update config.sh (Internal function)
update_config() {
    local tmp_file="${CONFIG_FILE}.tmp"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "#!/usr/bin/env bash" > "$CONFIG_FILE"
    fi

    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" 2>/dev/null || true

    # Remove old WORDLISTS block if exists
    if grep -q "WORDLISTS=(" "$CONFIG_FILE"; then
        sed '/^WORDLISTS=(/,/)/d' "$CONFIG_FILE" > "$tmp_file"
    else
        cat "$CONFIG_FILE" > "$tmp_file"
    fi

    # Append new array
    {
        echo ""
        echo "WORDLISTS=("
        for path in "${WORDLISTS[@]}"; do
            echo "    \"$path\""
        done
        echo ")"
    } >> "$tmp_file"

    mv "$tmp_file" "$CONFIG_FILE"
    echo -e "${GREEN}-> config.sh updated successfully.${NC}"
}

# 3. Main menu loop
while true; do
    print_header "WORDLIST MANAGEMENT"

    echo -e "Current wordlists: ${GREEN}${#WORDLISTS[@]}${NC}"
    echo "------------------------------------------------"
    echo " 1) Manually add path(s) (Returns to menu after)"
    echo " 2) Download rockyou.txt"
    echo " 3) Show current wordlists"
    echo " 4) Exit"
    echo "------------------------------------------------"

    read -p "Choice [1-4]: " choice

    case "$choice" in
        1)
            echo -e "\n${YELLOW}Paste path(s) or enter manually. Press Enter to process and return:${NC}"

            # Temporary storage to see if something was added
            added_any=false

            # Read input. Works for single lines and multi-line pastes.
            # The loop terminates when an empty line is encountered or EOF
            while IFS= read -r line; do
                # Clean input (remove quotes and trailing spaces)
                line="${line//\"/}"
                line="${line#"${line%%[![:space:]]*}"}"
                line="${line%"${line##*[![:space:]]}"}"

                [[ -z "$line" ]] && break

                if [[ -f "$line" ]]; then
                    # Strict duplicate check
                    already_in=false
                    for existing in "${WORDLISTS[@]}"; do
                        [[ "$existing" == "$line" ]] && already_in=true && break
                    done

                    if [ "$already_in" = false ]; then
                        WORDLISTS+=("$line")
                        echo -e "${GREEN}Added:${NC} $line"
                        added_any=true
                    else
                        echo -e "${YELLOW}Skipped (exists):${NC} $line"
                    fi
                else
                    echo -e "${RED}Error: File not found:${NC} $line"
                fi
            done

            # Only update and return if something happened
            if [ "$added_any" = true ]; then
                update_config
            fi
            echo -e "\nReturning to menu..."
            sleep 1
            ;;

        2)
            echo -e "\n${CYAN}Checking/Downloading rockyou.txt...${NC}"
            target_dir="$HOME/wordlists"
            mkdir -p "$target_dir"
            target="$target_dir/rockyou.txt"

            if [[ -f "$target" ]]; then
                echo -e "${YELLOW}File already exists at $target${NC}"
            else
                url="https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
                if curl -L -o "$target" "$url"; then
                    echo -e "${GREEN}Download complete.${NC}"
                else
                    echo -e "${RED}Download failed.${NC}"
                    read -p "Press Enter to continue..." dummy
                    continue
                fi
            fi

            already_in=false
            for existing in "${WORDLISTS[@]}"; do
                [[ "$existing" == "$target" ]] && already_in=true && break
            done

            if [ "$already_in" = false ]; then
                WORDLISTS+=("$target")
                update_config
            else
                echo "Path already registered."
            fi
            read -p "Press Enter to continue..." dummy
            ;;

        3)
            print_header "CURRENT WORDLISTS"
            if (( ${#WORDLISTS[@]} == 0 )); then
                echo "  (No wordlists added yet)"
            else
                for p in "${WORDLISTS[@]}"; do
                    echo -e "  ${BLUE}*${NC} $p"
                done
            fi
            echo "------------------------------------------------"
            read -p "Press Enter to continue..." dummy
            ;;

        4)
            echo "Exiting."
            exit 0
            ;;

        *)
            echo -e "${RED}Invalid option.${NC}"
            sleep 1
            ;;
    esac
done