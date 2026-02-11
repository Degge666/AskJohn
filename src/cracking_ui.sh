#!/bin/bash
# =============================================================================
# AskJohn - src/cracking_ui.sh (Full Artifact Management & Combat)
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
    echo -e "${GREEN}Garden synchronized. $found new artifacts secured.${NC}"
    sleep 1
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

            if [[ -n "$is_cracked" ]]; then
                status_text="SOLVED"
                color=$GREEN
            elif [[ "$type" == "-" || "$type" == "Unknown" ]]; then
                status_text="UNKNOWN"
                color=$RED
            else
                status_text="OPEN"
                color=$YELLOW
            fi

            echo -ne "${color}"
            printf "%-4s | %-15s | %-10s | %s\n" "$count" "$type" "$status_text" "$(basename "$p")"
            echo -ne "${NC}"
        done
    fi
    echo "------------------------------------------------------------------------------------------"
}

# --- VIEW: Weapon Selection (Combat Mode) ---
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
                print_header "SELECT A SCROLL FROM THE SHELF"
                local i=0; local books=()
                while read -r line; do
                    ((i++))
                    books[$i]="$line"
                    printf "${WHITE}%2d)${NC} %s\n" "$i" "$(basename "$line")"
                done < "$BASE_DIR/lib/wordlists.db"

                read -p "Which scroll shall he read? " bc
                if [[ "$bc" =~ ^[0-9]+$ ]] && [[ -n "${books[$bc]}" ]]; then
                    execute_wordlist_spell "$target" "${books[$bc]}" "$fmt"
                fi
            else
                echo -e "${RED}The Library is empty! Use the Great Library to add scrolls.${NC}"
                sleep 2
            fi
            ;;
        2)
            # Single Mode: Nutzt Informationen aus dem User-Kontext/GECOS
            execute_single_spell "$target" "$fmt"
            ;;
        3)
            # Ancient Rules Menu
            print_header "THE FORBIDDEN MANGLING PATTERNS"
            echo " 1) Word + Numbers  (e.g. Summer -> Summer24)"
            echo " 2) Simple Leet     (e.g. elite -> 3l1t3)"
            echo " 3) John's Default  (The classic ruleset)"
            echo " b) Back"
            read -p "Choose the mutation: " rc
            case $rc in
                1) execute_custom_rule_spell "$target" "Az\"[0-9][0-9]\"" "$fmt" ;;
                2) execute_custom_rule_spell "$target" "so0se3si1sa4sg9st1" "$fmt" ;;
                3) execute_john_standard_rules "$target" "$fmt" ;;
                *) return ;;
            esac
            ;;
        b) return ;;
    esac
}

# --- VIEW: Detailed Artifact Wisdom ---
show_artifact_details() {
    local target="$1"
    while true; do
        print_header "ARTIFACT WISDOM"
        echo -e "${BLUE}Path:${NC} $target"
        echo "----------------------------------------------------------------------"

        # Breakdown of the hashes inside the file
        local show_out=$($JOHN_PATH --show "$target" 2>/dev/null)
        while read -r line; do
            [[ -z "$line" ]] && continue
            local pass=$(echo "$show_out" | grep -F "$line" | cut -d: -f2)
            if [[ -n "$pass" ]]; then
                echo -e "Hash: ${WHITE}$line${NC} -> ${GREEN}SOLVED: $pass${NC}"
            else
                echo -e "Hash: ${WHITE}$line${NC} -> ${YELLOW}OPEN${NC}"
            fi
        done < "$target"

        echo "----------------------------------------------------------------------"
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

# --- MAIN: Hash Management (Phase 1) ---
add_new_riddle() {
    while true; do
        print_header "GIVE JOHN A RIDDLE - MANAGEMENT"
        display_artifact_table
        echo -e " 1) Import File  2) Paste String  3) Scavenger  4) Garden  q) Exit"
        read -p "Choice: " c
        case "$c" in
            1) read -e -p "Path: " p; local cp="${p//\"/}"; [[ -f "$cp" ]] && cp "$cp" "$BASE_DIR/temp/" && register_artifact "$BASE_DIR/temp/$(basename "$cp")" ;;
            2) read -p "Hash: " h; [[ -n "$h" ]] && f="$BASE_DIR/temp/man_$(date +%s).txt" && echo "$h" > "$f" && register_artifact "$f" ;;
            3) [[ -f "$BASE_DIR/src/scavenger_ui.sh" ]] && source "$BASE_DIR/src/scavenger_ui.sh" && enter_scavenger_path ;;
            4) explore_garden ;;
            q) return ;;
        esac
    done
}

# --- MAIN: Cracking Camp (Phase 2) ---
enter_cracking_camp() {
    while true; do
        print_header "THE CRACKING CAMP"
        display_artifact_table
        local arts=()
        [[ -s "$REGISTRY" ]] && while read -r line; do arts+=("$line"); done < "$REGISTRY"
        read -p "Select ID to Attack (or q): " sel
        [[ "$sel" == "q" ]] && return
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -le "${#arts[@]}" ]; then
            show_artifact_details "${arts[$(( ${#arts[@]} - sel ))]}"
        fi
    done
}