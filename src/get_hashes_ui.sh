#!/bin/bash
# =============================================================================
# AskJohn – src/get_hashes_ui.sh (The Scavenger's Menu)
# =============================================================================
source "$BASE_DIR/lib/converters.sh"

while true; do
    print_header "THE SCAVENGER'S PATH"
    echo -e " 1) ${CYAN}ZIP Artifact${NC}"
    echo -e " 2) ${CYAN}RAR Artifact${NC}"
    echo -e " 3) ${CYAN}Linux Shadow (Local)${NC}"
    echo -e " 4) ${CYAN}Windows Registry (Local)${NC}"
    echo -e " q) ${RED}Retreat to Gate${NC}"
    echo "------------------------------------------------"
    read -p "Select your path: " choice

    case "$choice" in
        1)
            read -e -p "Drag the ZIP artifact here: " file
            file="${file//\"/}" # Clean quotes
            out="$BASE_DIR/temp/zip_$(date +%s).hash"
            # Calling Logic Layer
            scavenge_zip "$file" "$out"
            echo -e "${GREEN}Artifact secured in cellar.${NC}"
            ;;
        2)
            # ... analog for RAR ...
            ;;
        3)
            out="$BASE_DIR/temp/linux_$(date +%s).hash"
            scavenge_linux_shadow "$out"
            echo -e "${GREEN}Linux secrets extracted.${NC}"
            ;;
        q) exit 0 ;;
    esac
    read -p "Press Enter to continue..." d
done