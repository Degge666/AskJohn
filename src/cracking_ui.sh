#!/bin/bash
# =============================================================================
# AskJohn - src/cracking_ui.sh (The Refined Artifact Cellar)
# =============================================================================

source "$BASE_DIR/lib/john_wrapper.sh"
REGISTRY="$BASE_DIR/lib/artifact_registry.db"
touch "$REGISTRY"

# --- CORE LOGIC ---
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

# --- HILFSFUNKTION: Präziser Status-Check ---
check_if_solved() {
    local target="$1"
    local info_file="${target}.info"
    [[ ! -f "$info_file" ]] && echo "OPEN" && return
    local formats=$(cat "$info_file")
    IFS=',' read -r -a fmt_arr <<< "$formats"
    for f in "${fmt_arr[@]}"; do
        local cracked=$($JOHN_PATH --show --format="$f" "$target" 2>/dev/null | grep -c ":")
        if [[ "$cracked" -gt 0 ]]; then
            echo "SOLVED"
            return
        fi
    done
    echo "OPEN"
}

# --- LOGIC: The Multi-Weapon Attack ---
execute_multi_format_attack() {
    local target="$1"
    local raw_fmts="$2"
    local attack_type="$3"
    local extra_param="$4"

    # --- 1. SCHRIFTROLLE DER OFFENBARUNG (Nano Vorschau) ---
    local preview="$BASE_DIR/temp/spell_preview.tmp"
    # Wir ermitteln den absoluten Pfad zu hashid.py für das manuelle Kopieren
    local hashid_path="$(realpath "$BASE_DIR/hashid.py" 2>/dev/null || echo "$BASE_DIR/hashid.py")"

    cat <<EOF > "$preview"
# BATTLE PLAN: INDIVIDUAL COMMANDS
# -----------------------------------------------------------------------------
# IDENTIFY MANUALLY (The Oracle's Formula):
python3 "$hashid_path" -e "$(realpath "$target")"

# CRACK MANUALLY (Copy one line at a time):
EOF
    IFS=',' read -r -a fmt_array <<< "$raw_fmts"
    for fmt in "${fmt_array[@]}"; do
        echo "$JOHN_PATH --format=$fmt ${extra_param:+--wordlist=$extra_param} temp/$(basename "$target")" >> "$preview"
    done
    echo -e "\n# [Instruction]: Close nano (Ctrl+X) to start the automated attack." >> "$preview"

    nano "$preview"
    rm -f "$preview"

    # --- 2. ECHTE AUSFÜHRUNG ---
    for current_fmt in "${fmt_array[@]}"; do
        print_header "ATTACKING WITH FORMAT: $current_fmt"
        rm -f ~/.john/john.rec 2>/dev/null

        case "$attack_type" in
            "wordlist") $JOHN_PATH --format="$current_fmt" --wordlist="$extra_param" "$target" ;;
            "single")   $JOHN_PATH --format="$current_fmt" --single "$target" ;;
            "standard") $JOHN_PATH --format="$current_fmt" "$target" ;;
            "rules")    $JOHN_PATH --format="$current_fmt" --rules="$extra_param" "$target" ;;
        esac

        # Prüfung ob gelöst
        if [[ $($JOHN_PATH --show --format="$current_fmt" "$target" 2>/dev/null | grep -c ":") -gt 0 ]]; then
            local pass=$($JOHN_PATH --show --format="$current_fmt" "$target" 2>/dev/null | cut -d: -f2 | head -n 1)
            echo -e "\n${GREEN}================================================${NC}"
            echo -e "${GREEN}SUCCESS! The Riddle has been solved!${NC}"
            echo -e "FORMAT: ${YELLOW}$current_fmt${NC}"
            echo -e "PASSWORD: ${BOLD}${WHITE}${BG_GREEN} $pass ${NC}"
            echo -e "${GREEN}================================================${NC}"
            read -p "The Oracle is pleased. Press Enter to return..."
            return
        fi

        echo -e "\n${RED}Format $current_fmt failed.${NC}"
        sleep 1
    done
    read -p "The attack has ended. Press Enter to return..."
}

# --- VIEW: Artifact Wisdom (Details) ---
show_artifact_details() {
    local target="$1"
    while true; do
        local status=$(check_if_solved "$target")
        local color=$YELLOW
        [[ "$status" == "SOLVED" ]] && color=$GREEN

        print_header "ARTIFACT WISDOM"
        echo -e "Path: $target"
        echo -e "Status: ${color}${status}${NC}"
        echo "------------------------------------------------"

        if [[ "$status" == "SOLVED" ]]; then
            local fmts=$(cat "${target}.info" 2>/dev/null)
            IFS=',' read -r -a f_arr <<< "$fmts"
            for f in "${f_arr[@]}"; do
                # Passwort extrahieren und farbig markieren
                local line=$($JOHN_PATH --show --format="$f" "$target" 2>/dev/null | grep ":")
                if [[ -n "$line" ]]; then
                    local h=$(echo "$line" | cut -d: -f1)
                    local p=$(echo "$line" | cut -d: -f2)
                    echo -e "${WHITE}$h${NC}:${BOLD}${GREEN}$p${NC} (Format: $f)"
                fi
            done
        else
            head -n 5 "$target"
        fi

        echo "------------------------------------------------"
        echo -e " 1) Attack  2) Oracle  3) Edit  q) Back"
        read -p "Decision: " d
        case "$d" in
            1) show_weapon_selection "$target" ;;
            2) source "$BASE_DIR/src/get_hash_info_ui.sh"; consult_oracle_for_file "$target" ;;
            3) nano "$target"; rm -f "${target}.info" ;;
            q) return ;;
        esac
    done
}

# --- WEAPON SELECTION ---
show_weapon_selection() {
    local target="$1"
    local fmts="auto"
    [[ -f "${target}.info" ]] && fmts=$(cat "${target}.info")

    print_header "CHOOSE YOUR WEAPON"
    echo -e "Target: $(basename "$target")"
    echo "------------------------------------------------"
    echo -e " 1) Wordlist Attack"
    echo -e " 2) Single Mode"
    echo -e " 3) Ancient Rules"
    echo -e " b) Back"
    echo "------------------------------------------------"
    read -p "Your choice: " weapon
    case "$weapon" in
        1)
            if [[ -s "$BASE_DIR/lib/wordlists.db" ]]; then
                print_header "SELECT A SCROLL"
                local i=0; local books=()
                while read -r line; do ((i++)); books[$i]="$line"; printf "${WHITE}%2d)${NC} %s\n" "$i" "$(basename "$line")"; done < "$BASE_DIR/lib/wordlists.db"
                read -p "Choice: " bc
                [[ "$bc" =~ ^[0-9]+$ ]] && [[ -n "${books[$bc]}" ]] && execute_multi_format_attack "$target" "$fmts" "wordlist" "${books[$bc]}"
            fi ;;
        2) execute_multi_format_attack "$target" "$fmts" "single" ;;
        3)
            echo " 1) Word + Numbers  2) Simple Leet  3) Default"
            read -p "Choice: " rc
            case $rc in
                1) execute_multi_format_attack "$target" "$fmts" "rules" "Az\"[0-9][0-9]\"" ;;
                2) execute_multi_format_attack "$target" "$fmts" "rules" "so0se3si1sa4sg9st1" ;;
                3) execute_multi_format_attack "$target" "$fmts" "standard" ;;
            esac ;;
        b) return ;;
    esac
}

# --- MANAGEMENT UI ---
display_artifact_table() {
    clean_registry
    local arts=()
    [[ -s "$REGISTRY" ]] && while read -r line; do arts+=("$line"); done < "$REGISTRY"
    echo -e "\n${WHITE}EXPLORE RIDDLES (Hash Overview)${NC}"
    echo "------------------------------------------------------------------------------------------"
    if [ ${#arts[@]} -eq 0 ]; then
        echo -e "${RED}The cellar is empty.${NC}"
    else
        printf "${WHITE}%-4s | %-20s | %-10s | %s${NC}\n" "ID" "Type" "Status" "Artifact Name"
        echo "------------------------------------------------------------------------------------------"
        local count=0
        for (( i=${#arts[@]}-1; i>=0; i-- )); do
            ((count++))
            local p="${arts[$i]}"
            local type_display="-"
            if [[ -f "${p}.info" ]]; then
                local raw_types=$(cat "${p}.info")
                local first_type=$(echo "$raw_types" | cut -d, -f1)
                type_display="$first_type"
            fi
            local status_text=$(check_if_solved "$p")
            local color=$WHITE
            [[ "$status_text" == "SOLVED" ]] && color=$GREEN || color=$YELLOW
            echo -ne "${color}"
            printf "%-4s | %-20s | %-10s | %s\n" "$count" "${type_display:0:19}" "$status_text" "$(basename "$p")"
            echo -ne "${NC}"
        done
    fi
    echo "------------------------------------------------------------------------------------------"
}

add_new_riddle() {
    while true; do
        print_header "GIVE JOHN A RIDDLE - MANAGEMENT"
        display_artifact_table
        echo -e " 1) Explore Garden  2) Write (String)  3) Scavenger  r) Remove  q) Back"
        read -p "Choice: " choice
        case "$choice" in
            1)
                for f in "$BASE_DIR/temp"/*; do [[ -f "$f" && "$f" != *.info ]] && register_artifact "$f"; done
                echo -e "${GREEN}Garden synchronized.${NC}"; sleep 1 ;;
            2)
                read -p "Paste hash: " h_code
                if [[ -n "$h_code" ]]; then
                    local new_file="$BASE_DIR/temp/man_$(date +%s).txt"
                    echo "$h_code" > "$new_file" && register_artifact "$new_file"
                    source "$BASE_DIR/src/get_hash_info_ui.sh" && consult_oracle_for_file "$new_file"
                fi ;;
            3) source "$BASE_DIR/src/scavenger_ui.sh" && enter_scavenger_path ;;
            r) # Purge Logik hier einfügen falls nötig
               echo "Purge not implemented in this view." ; sleep 1 ;;
            q) return ;;
        esac
    done
}

enter_cracking_camp() {
    while true; do
        display_artifact_table
        local arts=()
        [[ -s "$REGISTRY" ]] && while read -r line; do arts+=("$line"); done < "$REGISTRY"
        echo -e "\n Select ID or 'q':"
        read -p "ID / q: " sel
        [[ "$sel" == "q" ]] && return
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -le "${#arts[@]}" ]; then
            show_artifact_details "${arts[$(( ${#arts[@]} - sel ))]}"
        fi
    done
}