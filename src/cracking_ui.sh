#!/bin/bash
# =============================================================================
# AskJohn - src/cracking_ui.sh (The Refined Artifact Cellar)
# =============================================================================

source "$BASE_DIR/lib/john_wrapper.sh"
REGISTRY="$BASE_DIR/lib/artifact_registry.db"
touch "$REGISTRY"

# --- CORE LOGIC: Registry & Garden ---
register_artifact() {
    local target_path="$1"
    if ! grep -qxF "$target_path" "$REGISTRY" 2>/dev/null; then
        echo "$target_path" >> "$REGISTRY"
    fi
}

clean_registry() {
    [[ ! -f "$REGISTRY" ]] && return
    local tmp_reg=$(mktemp)
    while read -r entry; do
        [[ -f "$entry" ]] && echo "$entry" >> "$tmp_reg"
    done < "$REGISTRY"
    mv "$tmp_reg" "$REGISTRY"
}

explore_garden() {
    echo -e "${CYAN}Searching for unregistered treasures in temp/...${NC}"
    local found=0
    for f in "$BASE_DIR/temp"/*; do
        [[ -d "$f" || "$f" == *.info ]] && continue
        if ! grep -qxF "$f" "$REGISTRY" 2>/dev/null; then
            register_artifact "$f"
            ((found++))
        fi
    done
    [[ $found -gt 0 ]] && echo -e "${GREEN}Garden synchronized. $found new artifacts secured.${NC}" || echo -e "${YELLOW}No new artifacts found in the garden.${NC}"
    sleep 1
}

purge_artifact() {
    local arts=()
    [[ -s "$REGISTRY" ]] && while read -r line; do arts+=("$line"); done < "$REGISTRY"
    echo -e "${RED}WHICH RIDDLE SHALL BE STRUCK FROM THE RECORDS?${NC}"
    read -p "Enter ID (or 'c' to cancel): " p_id
    if [[ "$p_id" =~ ^[0-9]+$ ]] && [ "$p_id" -le "${#arts[@]}" ]; then
        local idx=$(( ${#arts[@]} - p_id ))
        local target="${arts[$idx]}"
        echo -e "${YELLOW}Vaporizing $(basename "$target")...${NC}"
        [[ "$target" == *"$BASE_DIR/temp/"* ]] && rm -f "$target"
        rm -f "${target}.info"
        grep -vxF "$target" "$REGISTRY" > "${REGISTRY}.tmp" && mv "${REGISTRY}.tmp" "$REGISTRY"
        echo -e "${GREEN}The records have been purged.${NC}"
        sleep 1
    fi
}

# --- VIEW: The Artifact Table ---
display_artifact_table() {
    clean_registry
    local arts=()
    [[ -s "$REGISTRY" ]] && while read -r line; do arts+=("$line"); done < "$REGISTRY"
    echo -e "\n${WHITE}EXPLORE RIDDLES (Hash Overview)${NC}"
    echo "------------------------------------------------------------------------------------------"
    if [ ${#arts[@]} -eq 0 ]; then
        echo -e "${RED}The cellar is empty.${NC}"
    else
        printf "${WHITE}%-4s | %-15s | %-10s | %s${NC}\n" "ID" "Type" "Status" "Artifact Name"
        echo "------------------------------------------------------------------------------------------"
        local count=0
        for (( i=${#arts[@]}-1; i>=0; i-- )); do
            ((count++))
            local p="${arts[$i]}"
            local type="-"
            [[ -f "${p}.info" ]] && type=$(head -n 1 "${p}.info" | cut -c1-14)
            local is_cracked=$($JOHN_PATH --show "$p" 2>/dev/null | grep -E "([1-9][0-9]* password hash(es)? cracked|1.+) ")
            local status_text="OPEN"
            local color=$WHITE
            if [[ -n "$is_cracked" ]]; then status_text="SOLVED"; color=$GREEN;
            elif [[ "$type" == "-" || "$type" == "Unknown" ]]; then status_text="UNKNOWN"; color=$RED;
            else status_text="OPEN"; color=$YELLOW; fi
            echo -ne "${color}"
            printf "%-4s | %-15s | %-10s | %s\n" "$count" "$type" "$status_text" "$(basename "$p")"
            echo -ne "${NC}"
        done
    fi
    echo "------------------------------------------------------------------------------------------"
}

# --- VIEW: Weapon Selection ---
show_weapon_selection() {
    local target="$1"
    local fmt=""
    [[ -f "${target}.info" ]] && fmt=$(head -n 1 "${target}.info" | awk '{print $1}')
    print_header "CHOOSE YOUR WEAPON"
    echo -e "Target: $(basename "$target")"
    echo "------------------------------------------------"
    echo -e " 1) ${WHITE}Send John to the Library${NC} (crack hash with Wordlist)"
    echo -e " 2) ${WHITE}Torture by repeating a Word${NC} (crack hash in single mode)"
    echo -e " 3) ${WHITE}Ancient Rules${NC} (Mangling/Custom rule cracking)"
    echo -e " b) Back to Details"
    echo "------------------------------------------------"
    read -p "Your choice: " weapon
    case "$weapon" in
        1)
            if [[ -s "$BASE_DIR/lib/wordlists.db" ]]; then
                print_header "SELECT A SCROLL"
                local i=0; local books=()
                while read -r line; do ((i++)); books[$i]="$line"; printf "${WHITE}%2d)${NC} %s\n" "$i" "$(basename "$line")"; done < "$BASE_DIR/lib/wordlists.db"
                read -p "Which scroll shall he read? " bc
                [[ "$bc" =~ ^[0-9]+$ ]] && [[ -n "${books[$bc]}" ]] && execute_wordlist_spell "$target" "${books[$bc]}" "$fmt"
            fi ;;
        2) execute_single_spell "$target" "$fmt" ;;
        3)
            print_header "FORBIDDEN MANGLING"
            echo " 1) Word + Numbers  2) Simple Leet  3) John's Default"
            read -p "Choice: " rc
            case $rc in
                1) execute_custom_rule_spell "$target" "Az\"[0-9][0-9]\"" "$fmt" ;;
                2) execute_custom_rule_spell "$target" "so0se3si1sa4sg9st1" "$fmt" ;;
                3) execute_john_standard_rules "$target" "$fmt" ;;
            esac ;;
        b) return ;;
    esac
}

show_artifact_details() {
    local target="$1"
    while true; do
        print_header "ARTIFACT WISDOM"
        echo -e "${BLUE}Path:${NC} $target"
        echo "------------------------------------------------------------------------------------------"

        # Tabellen-Header
        printf "${WHITE}%-3s | %-40s | %-10s | %-15s${NC}\n" "ID" "Hash / Riddle Content" "Status" "Potential Type"
        echo "------------------------------------------------------------------------------------------"

        local show_out=$($JOHN_PATH --show "$target" 2>/dev/null)
        local count=0

        while read -r line; do
            [[ -z "$line" ]] && continue
            ((count++))

            # Status prüfen (Cracked oder nicht)
            local pass=$(echo "$show_out" | grep -F "$line" | cut -d: -f2)
            local status_text="OPEN"
            local color=$YELLOW
            [[ -n "$pass" ]] && status_text="SOLVED" && color=$GREEN

            # Kurze Pattern-Analyse für die Anzeige (identisch zur Oracle-Logik)
            local h_content=$(echo "$line" | cut -d: -f1)
            local h_len=${#h_content}
            local p_type="Unknown"

            case $h_len in
                32)  p_type="MD5/NTLM" ;;
                40)  p_type="SHA-1" ;;
                64)  p_type="SHA-256" ;;
                128) p_type="SHA-512" ;;
                *)   [[ "$line" == *'$zip2$'* ]] && p_type="ZIP" || p_type="Special/Misc" ;;
            esac

            # Gekürzte Darstellung für sehr lange Hashes (z.B. ZIP)
            local display_hash=$line
            [[ ${#display_hash} -gt 40 ]] && display_hash="${display_hash:0:37}..."

            printf "${color}%-3s | %-40s | %-10s | %-15s${NC}\n" "$count" "$display_hash" "$status_text" "$p_type"
            [[ -n "$pass" ]] && echo -e "    ${GREEN}└─ Cracked Password: $pass${NC}"

        done < "$target"

        echo "------------------------------------------------------------------------------------------"
        echo -e " 1) Attack  2) Oracle (Identify)  3) Edit File  q) Back"
        read -p "Decision: " d
        case "$d" in
            1) show_weapon_selection "$target" ;;
            2) [[ -f "$BASE_DIR/src/get_hash_info_ui.sh" ]] && source "$BASE_DIR/src/get_hash_info_ui.sh" && consult_oracle_for_file "$target" ;;
            3) nano "$target"; [[ -f "${target}.info" ]] && rm "${target}.info" ;;
            q) return ;;
        esac
    done
}

# --- MAIN: Hash Management ---
add_new_riddle() {
    while true; do
        print_header "GIVE JOHN A RIDDLE - MANAGEMENT"
        display_artifact_table
        echo -e " 1) Explore Garden (add Hash by Path or Filename)"
        echo -e " 2) Write down a riddle (Add hash String)"
        echo -e " 3) Go the Scavenger's Path (get hash from File or System)"
        echo -e " r) ${RED}Remove Artifact${NC}"
        echo -e " q) Back to Main Gate"
        echo "------------------------------------------------"
        read -p "Your choice: " choice

        if [[ "$choice" == /* ]] || [[ "$choice" == *.* ]]; then
            local src="${choice//\"/}"
            if [[ -f "$src" ]]; then
                local dest="$BASE_DIR/temp/$(basename "$src")"
                cp "$src" "$dest" && register_artifact "$dest"
                echo -e "${GREEN}Success: Artifact secured!${NC}"
                [[ -f "$BASE_DIR/src/get_hash_info_ui.sh" ]] && source "$BASE_DIR/src/get_hash_info_ui.sh" && consult_oracle_for_file "$dest"
            fi
            sleep 1; continue
        fi

        case "$choice" in
            1)
                explore_garden
                read -e -p "Or enter manual path to import: " p
                if [[ -n "$p" ]]; then
                    local clean_p="${p//\"/}"
                    if [[ -f "$clean_p" ]]; then
                        local dest="$BASE_DIR/temp/$(basename "$clean_p")"
                        cp "$clean_p" "$dest" && register_artifact "$dest"
                        echo -e "${GREEN}Success: File imported!${NC}"
                        [[ -f "$BASE_DIR/src/get_hash_info_ui.sh" ]] && source "$BASE_DIR/src/get_hash_info_ui.sh" && consult_oracle_for_file "$dest"
                    fi
                fi
                sleep 1 ;;
            2)
                read -p "Paste hash string: " h_code
                if [[ -n "$h_code" ]]; then
                    local new_file="$BASE_DIR/temp/man_$(date +%Y%m%d_%H%M%S).txt"
                    echo "$h_code" > "$new_file" && register_artifact "$new_file"
                    echo -e "${GREEN}Success: Riddle written down!${NC}"
                    [[ -f "$BASE_DIR/src/get_hash_info_ui.sh" ]] && source "$BASE_DIR/src/get_hash_info_ui.sh" && consult_oracle_for_file "$new_file"
                fi
                sleep 1 ;;
            3) [[ -f "$BASE_DIR/src/scavenger_ui.sh" ]] && source "$BASE_DIR/src/scavenger_ui.sh" && enter_scavenger_path ;;
            r) purge_artifact ;;
            q) return ;;
        esac
    done
}

enter_cracking_camp() {
    while true; do
        print_header "THE CRACKING CAMP"
        display_artifact_table
        local arts=()
        [[ -s "$REGISTRY" ]] && while read -r line; do arts+=("$line"); done < "$REGISTRY"
        echo -e "\n Select ID to start attack or 'q' to retreat:"
        echo "------------------------------------------------"
        read -p "ID / q: " sel
        [[ "$sel" == "q" ]] && return
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -le "${#arts[@]}" ]; then
            show_artifact_details "${arts[$(( ${#arts[@]} - sel ))]}"
        fi
    done
}