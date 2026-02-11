#!/bin/bash
# =============================================================================
# AskJohn - src/get_hash_info_ui.sh (Consult the Oracle)
# =============================================================================
source "$BASE_DIR/lib/get_hash_info_lib.sh"

# This can be called from the Main Gate
enter_oracle_chamber() {
    while true; do
        print_header "THE ORACLE'S CHAMBER"
        echo -e " 1) ${WHITE}Identify Hash Manually${NC} (Paste a string)"
        echo -e " 2) ${WHITE}Analyze Local Artifacts${NC} (Batch process temp/)"
        echo -e " q) ${RED}Leave the Chamber${NC}"
        echo "------------------------------------------------"
        read -p "What do you seek? " choice

        case "$choice" in
            1)
                read -p "Paste your hash: " manual_hash
                local types=$(identify_hash_format "$manual_hash")
                echo -e "${GREEN}Possible types:${NC} $types"
                read -p "Press Enter..." d
                ;;
            2)
                echo "Analyzing all scrolls in the cellar..."
                for f in "$BASE_DIR"/temp/*.{hash,tmp}; do
                    [[ -e "$f" ]] || continue
                    analyze_artifact_file "$f"
                    echo " [+] $(basename "$f") identified."
                done
                sleep 1
                ;;
            q) return ;;
        esac
    done
}

# This is called directly from cracking_ui.sh (Option 2 in details)
consult_oracle_for_file() {
    local target="$1"
    echo -e "${CYAN}The Oracle is examining the artifact...${NC}"
    analyze_artifact_file "$target"
    echo -e "${GREEN}Identification complete. Wisdom stored in .info file.${NC}"
    sleep 1
}