#!/bin/bash
# =============================================================================
# AskJohn – src/identify_hash.sh (Identifizierung mit Clean UI)
# =============================================================================
source "$BASE_DIR/src/common.sh"
TEMP_DIR="$BASE_DIR/temp"

while true; do
    print_header "IDENTIFY HASH"

    # Hashes auflisten
    files=($(ls -t "$TEMP_DIR" 2>/dev/null | grep -v "\.info$" | grep -E "\.(hash|tmp)$"))

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Keine Hashes zum Identifizieren gefunden.${NC}"
        read -p "Enter zum Zurückkehren..." d; exit 0
    fi

    i=0; for f in "${files[@]}"; do echo " $((++i))) $f"; done
    echo -e " q) ${RED}Zurück zum Hauptmenü${NC}"
    echo "------------------------------------------------"
    read -p "Datei wählen [1-$i/q]: " sel

    # Zurück-Option
    [[ "$sel" == "q" || "$sel" == "Q" ]] && exit 0

    if [[ "$sel" =~ ^[0-9]+$ ]] && [[ "$sel" -le $i ]]; then
        target="$TEMP_DIR/${files[$((sel-1))]}"

        echo -e "\n${YELLOW}Analysiere Format...${NC}"

        # Wir führen John mit --list=formats aus oder nutzen die Erkennung
        # --pot=dummy verhindert, dass John die echte pot-Datei nutzt
        detected=$(john "$target" 2>&1 | grep -i "recognized as" | sed "s/.*recognized as '//;s/'.*//")

        if [[ -z "$detected" ]]; then
            echo -e "${RED}John konnte kein eindeutiges Format finden.${NC}"
            read -p "Format manuell eingeben (z.B. raw-md5) oder leer lassen: " manual
            detected="$manual"
        fi

        if [[ -n "$detected" ]]; then
            # Falls mehrere Formate (Ambiguity) erkannt wurden, nehmen wir das erste
            # oder zeigen sie kurz an.
            first_fmt=$(echo "$detected" | awk '{print $1}')
            echo "$first_fmt" > "${target}.info"
            echo -e "${GREEN}Format identifiziert: $first_fmt${NC}"
            echo "Info wurde gespeichert."
        fi

        read -p "Enter..." d
    fi
done