#!/bin/bash
# =============================================================================
# AskJohn - src/scavenger_ui.sh (The Artifact Converter)
# =============================================================================

check_tool_availability() {
    local tool=$1
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}Error: $tool is not installed or not in PATH.${NC}"
        return 1
    fi
    return 0
}

convert_artifact() {
    local source_file="$1"
    local type="$2"
    local output_file="$BASE_DIR/temp/scavenged_$(date +%s).hash"

    print_header "SCAVENGING ARTIFACT"
    echo -e "Target: ${CYAN}$source_file${NC}"
    echo -e "Process: ${WHITE}Extracting $type hash...${NC}"
    echo "------------------------------------------------"

    case $type in
        "zip")
            if check_tool_availability "zip2john"; then
                zip2john "$source_file" > "$output_file" 2>/dev/null
            fi
            ;;
        "rar")
            if check_tool_availability "rar2john"; then
                rar2john "$source_file" > "$output_file" 2>/dev/null
            fi
            ;;
        "pdf")
            if check_tool_availability "pdf2john"; then
                pdf2john "$source_file" > "$output_file" 2>/dev/null
            fi
            ;;
        "unshadow")
            # --- NEU: System Extraktion ---
            echo -e "${YELLOW}Requesting root powers to merge /etc/shadow...${NC}"
            sudo unshadow /etc/passwd /etc/shadow > "$output_file" 2>/dev/null
            ;;
    esac

    if [[ -s "$output_file" ]]; then
        echo -e "${GREEN}Success! Hash extracted to temp cellar.${NC}"
        echo "------------------------------------------------"
        # Sofort dem Orakel zur Identifizierung vorlegen
        source "$BASE_DIR/src/get_hash_info_ui.sh"
        consult_oracle_for_file "$output_file"

        # In den Keller (Registry) aufnehmen
        source "$BASE_DIR/src/cracking_ui.sh"
        register_artifact "$output_file"
    else
        echo -e "${RED}Scavenging failed or tool produced no output.${NC}"
        rm -f "$output_file"
    fi
    sleep 2
}

enter_scavenger_path() {
    while true; do
        print_header "THE SCAVENGER'S PATH"
        echo -e "Which artifact shall be stripped of its secrets?"
        echo -e " 1) ZIP Archive (.zip)"
        echo -e " 2) RAR Archive (.rar)"
        echo -e " 3) PDF Document (.pdf)"
        echo -e " 4) Linux System (/etc/shadow)"
        echo -e " q) Back to Main Menu"
        echo "------------------------------------------------"
        read -p "Your choice: " scav_choice

        case "$scav_choice" in
            1|2|3)
                read -e -p "Enter path to file: " file_path
                # Tilde zu Home-Pfad expandieren falls nötig
                file_path="${file_path/#\~/$HOME}"

                if [[ -f "$file_path" ]]; then
                    case "$scav_choice" in
                        1) convert_artifact "$file_path" "zip" ;;
                        2) convert_artifact "$file_path" "rar" ;;
                        3) convert_artifact "$file_path" "pdf" ;;
                    esac
                else
                    echo -e "${RED}File not found!${NC}"
                    sleep 1
                fi
                ;;
            4)
                # Direktaufruf für lokale System-Hashes
                convert_artifact "Local System" "unshadow"
                ;;
            q) return ;;
        esac
    done
}