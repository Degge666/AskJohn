#!/bin/bash
# =============================================================================
# AskJohn - src/library_ui.sh (The Great Library of Wordlists)
# =============================================================================

WORDLIST_DB="$BASE_DIR/lib/wordlists.db"
touch "$WORDLIST_DB"

register_wordlist() {
    local wp="$1"
    if ! grep -qxF "$wp" "$WORDLIST_DB" 2>/dev/null; then
        echo "$wp" >> "$WORDLIST_DB"
        echo -e "${GREEN}The scroll has been archived in the library.${NC}"
    else
        echo -e "${YELLOW}This scroll is already known to the librarians.${NC}"
    fi
}

list_wordlists() {
    print_header "THE ARCHIVED SCROLLS"
    if [[ ! -s "$WORDLIST_DB" ]]; then
        echo -e "${RED}The shelves are dusty and empty.${NC}"
    else
        local i=0
        while read -r line; do
            ((i++))
            echo -e "${WHITE}$i)${NC} $(basename "$line") ${CYAN}($line)${NC}"
        done < "$WORDLIST_DB"
    fi
    echo "------------------------------------------------"
}

manage_library() {
    while true; do
        print_header "THE GREAT LIBRARY"
        list_wordlists
        echo -e " 1) Register a new Wordlist (Path)"
        echo -e " 2) Search for local Wordlists (/usr/share/wordlists etc.)"
        echo -e " r) Clear Library Records"
        echo -e " q) Return to Main Gate"
        echo "------------------------------------------------"
        read -p "Your desire? " lib_choice

        case "$lib_choice" in
            1)
                read -e -p "Enter path to wordlist: " wl_path
                wl_path="${wl_path/#\~/$HOME}"
                if [[ -f "$wl_path" ]]; then
                    register_wordlist "$wl_path"
                else
                    echo -e "${RED}That scroll does not exist!${NC}"
                fi
                sleep 1 ;;
            2)
                echo -e "${CYAN}Scouting the surrounding lands for wordlists...${NC}"
                # Suche an typischen Orten (Linux & macOS)
                local search_paths=("/usr/share/wordlists" "/usr/share/dict" "/opt/wordlists")
                for sp in "${search_paths[@]}"; do
                    if [[ -d "$sp" ]]; then
                        echo -e "Found archives in $sp:"
                        find "$sp" -type f -name "*.txt" -o -name "*.lst" | head -n 10
                    fi
                done
                read -e -p "Copy a path from above to register: " manual_p
                [[ -f "$manual_p" ]] && register_wordlist "$manual_p"
                sleep 2 ;;
            r)
                > "$WORDLIST_DB"
                echo -e "${RED}The library has been purged.${NC}"
                sleep 1 ;;
            q) return ;;
        esac
    done
}