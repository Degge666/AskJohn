#!/bin/bash
# --- THE CAMP COUNSELOR (UI Only) ---
source "$BASE_DIR/lib/cracking_engine.sh"

while true; do
    print_header "THE CRACKING CAMP"
    # ... (Menü-Logik: artifacts auflisten, Wahl treffen) ...

    echo " 1) Ask John's Friend (Wordlist)"
    read -p "Weapon: " weapon

    case "$weapon" in
        1)
            # UI sammelt Daten
            read -p "Choose Scroll: " scroll
            # UI ruft Logik auf
            cast_wordlist_attack "$target" "$scroll" "$saved_format"
            ;;
    esac
done