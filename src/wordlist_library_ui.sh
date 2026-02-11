#!/bin/bash
# =============================================================================
# AskJohn - src/wordlist_library_ui.sh (The Great Library View)
# =============================================================================
source "$BASE_DIR/lib/wordlist_library.sh"

manage_wordlist_library() {
    while true; do
        print_header "THE GREAT LIBRARY"

        # Count current entries in the standardized index
        local entry_count=0
        [[ -f "$WORDLIST_INDEX" ]] && entry_count=$(wc -l < "$WORDLIST_INDEX" | xargs)

        echo -e "Your collection currently holds ${WHITE}$entry_count${NC} books."
        echo "------------------------------------------------"
        echo -e " 1) ${WHITE}Add a new Book${NC} (Manual path)"
        echo -e " 2) ${WHITE}Explore Landscape${NC} (Scan directory)"
        echo -e " 3) ${WHITE}Fetch Foreign Book${NC} (Get rockyou.txt)"
        echo -e " v) ${CYAN}View Library Index${NC}"
        echo -e " q) ${RED}Return to Gate${NC}"
        echo "------------------------------------------------"
        read -p "What is your command, Master Librarian? " choice

        case "$choice" in
            1)
                read -e -p "Provide the path to the book: " manual_path
                local clean_path="${manual_path//\"/}"
                if [[ -f "$clean_path" ]]; then
                    echo "$clean_path" >> "$WORDLIST_INDEX"
                    sort -u "$WORDLIST_INDEX" -o "$WORDLIST_INDEX"
                    echo -e "${GREEN}Path added to wordlists.db.${NC}"
                else
                    echo -e "${RED}File not found!${NC}"
                fi
                ;;
            2)
                read -e -p "Which region shall we scout? (Path): " scout_path
                scan_wordlists "${scout_path//\"/}"
                ;;
            3)
                fetch_famous_wordlist
                ;;
            v)
                print_header "LIBRARY INDEX (wordlists.db)"
                if [[ -s "$WORDLIST_INDEX" ]]; then
                    cat -n "$WORDLIST_INDEX" | less -R
                else
                    echo -e "${YELLOW}The database is empty.${NC}"
                    read -p "Press Enter..." d
                fi
                ;;
            q) return ;;
        esac
    done
}