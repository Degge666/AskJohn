#!/bin/bash
# =============================================================================
# AskJohn - src/cracking_ui.sh (FULL VERSION - Corrected)
# =============================================================================
source "$BASE_DIR/lib/john_wrapper.sh"

# --- HELPER: Path Shortener ---
smart_shorten_path() {
    local full_path="$1"
    local filename=$(basename "$full_path")
    local dir_part=$(dirname "$full_path")
    local max_len=45

    if [ ${#full_path} -le $max_len ]; then
        echo "$full_path"
    else
        local shortened_dir="...${dir_part: -20}"
        echo "$shortened_dir/$filename"
    fi
}

# --- VIEW: Internal Logic for Hash Breakdown ---
display_hash_breakdown() {
    local target_path="$1"
    local cracked_output=$(john --show "$target_path" 2>/dev/null)
    local line_count=0

    while read -r raw_hash; do
        [[ -z "$raw_hash" ]] && continue
        ((line_count++))
        echo -e "${CYAN}--- Hash #$line_count ---${NC}"

        local password=$(echo "$cracked_output" | grep "${raw_hash:0:20}" | cut -d: -f2)
        if [[ -n "$password" ]]; then
            echo -e "Status:   ${GREEN}SOLVED${NC}"
            echo -e "Password: ${GREEN}$password${NC}"
        else
            echo -e "Status:   ${YELLOW}OPEN${NC}"
            echo -e "Password: ${WHITE}(Still hidden in shadows)${NC}"
        fi

        echo -ne "Types:    "
        if [[ -f "${target_path}.info" ]]; then
            local possible_types=($(cat "${target_path}.info"))
            for t in "${possible_types[@]}"; do
                if [[ -n "$password" ]]; then
                    [[ "$t" == "${possible_types[0]}" ]] && echo -ne "${GREEN}$t ${NC}" || echo -ne "${RED}$t ${NC}"
                else
                    echo -ne "${WHITE}$t ${NC}"
                fi
            done
            echo ""
        else
            echo -e "${WHITE}Unknown (Consult the Oracle first)${NC}"
        fi

        echo -e "Salt:     ${WHITE}Not identified yet${NC}"
        echo -e "Raw Hash: ${WHITE}$raw_hash${NC}"
        echo ""
    done < "$target_path"
}

# --- VIEW: Detailed Artifact Wisdom ---
show_artifact_details() {
    local target_path="$1"
    while true; do
        print_header "ARTIFACT ANCIENT WISDOM"
        echo -e "${BLUE}Location:${NC} $target_path"
        echo "----------------------------------------------------------------------"

        display_hash_breakdown "$target_path"

        echo "----------------------------------------------------------------------"
        echo -e " 1) ${WHITE}Attack this Riddle${NC} (Choose Weapon)"
        echo -e " 2) ${WHITE}Ask an Oracle${NC} (Identify Hash Types)"
        echo -e " 3) ${WHITE}Rewrite the Script${NC} (Edit File Manually)"
        echo -e " q) ${RED}Return to List${NC}"
        echo "------------------------------------------------"
        read -p "Your decision: " sub_choice

        case "$sub_choice" in
            1) show_weapon_selection "$target_path" ;;
            2)
                # Integrating Oracle module
                [[ -f "$BASE_DIR/src/oracle_ui.sh" ]] && source "$BASE_DIR/src/oracle_ui.sh"
                consult_oracle_for_file "$target_path"
                ;;
            3) edit_artifact_manually "$target_path" ;;
            q) return ;;
        esac
    done
}

# --- VIEW: Weapon Selection (The Missing Piece) ---
show_weapon_selection() {
    local target="$1"
    local saved_format=""
    [[ -f "${target}.info" ]] && saved_format=$(head -n 1 "${target}.info")

    print_header "CHOOSE YOUR WEAPON"
    echo -e "Target: $(basename "$target")"
    echo "------------------------------------------------"
    echo " 1) Ask John's Friend (Wordlist Mode)"
    echo " 2) Lone Wolf Strike (Single Crack Mode)"
    echo " 3) Ancient Rules (Custom Mangling)"
    echo " b) Back to Details"
    echo "------------------------------------------------"
    read -p "Your choice: " weapon

    case "$weapon" in
        1)
            # Hier binden wir später die wordlists.db Auswahl ein
            read -e -p "Provide your scroll (wordlist path): " scroll
            execute_wordlist_spell "$target" "${scroll//\"/}" "$saved_format"
            ;;
        2)
            execute_single_spell "$target" "$saved_format"
            ;;
        b) return ;;
    esac
}

# --- LOGIC: Manual Editing ---
edit_artifact_manually() {
    local target="$1"
    local editor_cmd="nano"
    echo -e "${YELLOW}Opening the artifact for manual changes...${NC}"
    sleep 1
    $editor_cmd "$target"

    if [[ -f "${target}.info" ]]; then
        echo -e "${YELLOW}Artifact changed. Shall I discard the old Oracle wisdom? (y/n)${NC}"
        read -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] && rm "${target}.info"
    fi
}

# --- MAIN VIEW: The Table ---
enter_cracking_camp() {
    while true; do
        print_header "THE RIDDLES"
        local artifacts=($(ls -t "$BASE_DIR/temp" 2>/dev/null | grep -E "\.(hash|tmp)$"))

        if [ ${#artifacts[@]} -eq 0 ]; then
            echo -e "${RED}The cellar is empty.${NC}"; read -p "Enter..." d; return
        fi

        printf "${WHITE}%-4s | %-15s | %-10s | %s${NC}\n" "ID" "Hash-Type" "Status" "Path/File"
        echo "------------------------------------------------------------------------------------------"

        local i=0
        for a in "${artifacts[@]}"; do
            ((i++))
            local target_path="$BASE_DIR/temp/$a"
            local h_type="-"
            [[ -f "${target_path}.info" ]] && h_type=$(head -n 1 "${target_path}.info" | cut -c1-14)

            local status_text="OPEN"
            john --show "$target_path" 2>/dev/null | grep -q "password" && status_text="SOLVED"
            local display_path=$(smart_shorten_path "$target_path")

            if [ "$status_text" == "SOLVED" ]; then
                echo -ne "${GREEN}"
                printf "%-4s | %-15s | %-10s | %s" "$i" "$h_type" "$status_text" "$display_path"
                echo -e "${NC}"
            else
                printf "%-4s | %-15s | %-10s | %s\n" "$i" "$h_type" "$status_text" "$display_path"
            fi
        done

        echo -e "\n q) Retreat to Main Gate"
        read -p "Select ID for Details or 'q': " sel
        [[ "$sel" == "q" ]] && return

        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -le "$i" ]; then
            show_artifact_details "$BASE_DIR/temp/${artifacts[$((sel-1))]}"
        fi
    done
}