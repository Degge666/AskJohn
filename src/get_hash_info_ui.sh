#!/bin/bash
# =============================================================================
# AskJohn - src/get_hash_info_ui.sh (The Detailed Spurensicherung Oracle)
# =============================================================================

# Hilfsfunktion: Ruft John's interne Formate auf für detailliertere Vorschläge
deep_hash_analysis() {
    local target="$1"
    local sample=$(head -n 1 "$target" | cut -d: -f1)
    echo -e "${CYAN}Performing Deep Inspection of the hash structure...${NC}"

    # John's interne Datenbank für Formate abfragen, die zum Sample passen könnten
    $JOHN_PATH "$target" --list=format-details 2>/dev/null | grep -i "Format name" | head -n 5
}

consult_oracle_for_file() {
    local target="$1"
    [[ ! -f "$target" ]] && return

    print_header "CONSULTING THE ORACLE"
    echo -e "Analyzing artifact: ${CYAN}$(basename "$target")${NC}"
    echo -e "${WHITE}The Oracle stares into the abyss of the data...${NC}"
    echo "------------------------------------------------"

    local all_candidates=()
    echo -e "${WHITE}The Oracle scans every line of the scroll...${NC}"
    echo "------------------------------------------------"

    # --- VERBESSERTE SCHLEIFE: Mit Zeilen-Referenz und Preview ---
    local line_num=0
    while read -r line; do
        [[ -z "$line" ]] && continue
        ((line_num++))

        # Vorschau der ersten 8 Zeichen des Hashes für den Kontext
        local h_preview=$(echo "$line" | cut -c1-8)

        # 1. Spezial-Erkennung für Archive (ZIP, RAR, Office)
        if [[ "$line" == *'$zip2$'* ]] || [[ "$line" == *'$pkzip$'* ]]; then
            echo -e "Line $line_num ($h_preview...): ${GREEN}Detected ZIP Archive signature${NC}"
            all_candidates+=("zip")
        elif [[ "$line" == *'$rar5$'* ]]; then
            echo -e "Line $line_num ($h_preview...): ${GREEN}Detected RAR5 Archive signature${NC}"
            all_candidates+=("rar5")
        elif [[ "$line" == *'$office$'* ]]; then
            echo -e "Line $line_num ($h_preview...): ${GREEN}Detected MS Office Document signature${NC}"
            all_candidates+=("office")
        else
            # 2. Mathematische Prüfung (hash-id Logik) basierend auf der Länge
            local clean_h=$(echo "$line" | cut -d: -f1 | cut -d'$' -f1)
            local h_len=${#clean_h}

            case $h_len in
                32)
                    echo -e "Line $line_num ($h_preview...): ${GREEN}MD5/NTLM (Len 32)${NC}"
                    all_candidates+=("nt" "raw-md5" "md4") ;;
                40)
                    echo -e "Line $line_num ($h_preview...): ${GREEN}SHA-1 (Len 40)${NC}"
                    all_candidates+=("raw-sha1" "mysql-sha1") ;;
                64)
                    echo -e "Line $line_num ($h_preview...): ${GREEN}SHA-256 (Len 64)${NC}"
                    all_candidates+=("raw-sha256") ;;
                128)
                    echo -e "Line $line_num ($h_preview...): ${GREEN}SHA-512 (Len 128)${NC}"
                    all_candidates+=("raw-sha512") ;;
                *)
                    echo -e "Line $line_num ($h_preview...): ${RED}Unknown Pattern (Len $h_len)${NC}" ;;
            esac
        fi
    done < "$target"

    # --- Eindeutige Werte extrahieren & zusammenführen ---
    local final_candidates
    final_candidates=$(echo "${all_candidates[@]}" | tr ' ' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')

    # 3. Fallback: Falls John vage ist oder die Längenprüfung nichts fand
    if [[ -z "$final_candidates" || "$final_candidates" == "Unknown" ]]; then
        echo "------------------------------------------------"
        echo -e "${YELLOW}John is vague. Calling the Deep Spirits...${NC}"

        # Präzise Extraktion: Wir suchen nach dem Text in den Klammern nach "Loaded X password hashes"
        local full_out=$($JOHN_PATH "$target" 2>&1)
        local auto_format=$(echo "$full_out" | grep -i "Loaded" | head -n 1 | sed -n 's/.*(\([^)]*\)).*/\1/p' | cut -d',' -f1 | xargs)

        # Validierung: Wir lassen nur zu, was nicht wie eine Statusmeldung aussieht
        if [[ -n "$auto_format" && "$auto_format" != "hash"* && "$auto_format" != "loaded"* && "$auto_format" != "no"* ]]; then
            final_candidates="$auto_format"
        else
            deep_hash_analysis "$target"
            final_candidates="Unknown"
        fi
    fi

    echo "------------------------------------------------"
    echo -e "The Oracle suggests: ${YELLOW}'$final_candidates'${NC}"

    # --- AUTOMATISCHE WEISHEIT (Keine Abfrage mehr) ---
    if [[ -n "$final_candidates" && "$final_candidates" != "Unknown" ]]; then
        echo "$final_candidates" > "${target}.info"
        echo -e "${GREEN}Wisdom automatically carved into the records.${NC}"
    else
        echo -e "${RED}The Oracle's words remain unwritten (Unknown format).${NC}"
    fi
    echo "------------------------------------------------"
    sleep 1
}

identify_string() {
    local h_string="$1"
    [[ -z "$h_string" ]] && return
    local tmp_file="$BASE_DIR/temp/oracle_query.tmp"
    echo "$h_string" > "$tmp_file"

    consult_oracle_for_file "$tmp_file"

    if [[ -f "${tmp_file}.info" ]]; then
        echo "------------------------------------------------"
        # Hier lassen wir die Abfrage zur Speicherung im Keller,
        # da der User entscheiden muss, ob er diesen Test-Hash behalten will.
        read -p "Secure this new riddle in the cellar? (y/n): " secure
        if [[ "$secure" == "y" ]]; then
            local ts=$(date +%s)
            local final_name="$BASE_DIR/temp/oracle_find_${ts}.txt"
            mv "$tmp_file" "$final_name"
            mv "${tmp_file}.info" "${final_name}.info"

            source "$BASE_DIR/src/cracking_ui.sh"
            register_artifact "$final_name"
            echo -e "${GREEN}Riddle secured as oracle_find_${ts}.txt${NC}"
        else
            rm -f "$tmp_file" "${tmp_file}.info"
        fi
    else
        rm -f "$tmp_file"
    fi
    sleep 1
}

enter_oracle_chamber() {
    while true; do
        print_header "THE ORACLE'S CHAMBER"
        echo -e " 1) Identify Hash String (Deep Inspection)"
        echo -e " 2) Analyze Existing Artifacts (Select from Cellar)"
        echo -e " q) Leave the Chamber"
        echo "------------------------------------------------"
        read -p "What do you seek? " o_choice
        case "$o_choice" in
            1)
                read -p "Paste your hash: " h_input
                identify_string "$h_input"
                ;;
            2)
                source "$BASE_DIR/src/cracking_ui.sh"
                display_artifact_table
                local arts=()
                [[ -s "$REGISTRY" ]] && while read -r line; do arts+=("$line"); done < "$REGISTRY"

                read -p "Select ID to identify: " a_id
                if [[ "$a_id" =~ ^[0-9]+$ ]] && [ "$a_id" -le "${#arts[@]}" ]; then
                    local selected_idx=$(( ${#arts[@]} - a_id ))
                    consult_oracle_for_file "${arts[$selected_idx]}"
                fi
                ;;
            q)
                return
                ;;
        esac
    done
}