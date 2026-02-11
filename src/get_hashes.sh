#!/bin/bash
source "$BASE_DIR/src/common.sh"

while true; do
    print_header "ENVIRONMENT / CONVERTER"
    echo " 1) ZIP/RAR to John"
    echo " 2) Linux /etc/shadow (Unshadow)"
    echo " 3) Windows SAM/SYSTEM (Local)"
    echo " 4) Remote System (via SSH)"
    echo " q) Zurück"
    read -p "Wahl: " c
    case "$c" in
        1)
            read -e -p "Datei-Pfad: " p
            p="${p//\"/}"
            if [[ "$p" == *.zip ]]; then zip2john "$p" > "$BASE_DIR/temp/zip.hash"
            else rar2john "$p" > "$BASE_DIR/temp/rar.hash"; fi ;;
        2)
            sudo unshadow /etc/passwd /etc/shadow > "$BASE_DIR/temp/linux.hash" ;;
        3)
            read -p "SYSTEM path: " sys; read -p "SAM path: " sam
            samdump2 "$sys" "$sam" > "$BASE_DIR/temp/windows.hash" ;;
        4)
            [[ -z "$SSH_CMD" ]] && { echo "Kein SSH konfiguriert!"; sleep 1; continue; }
            $SSH_CMD "sudo unshadow /etc/passwd /etc/shadow" > "$BASE_DIR/temp/remote.hash" ;;
        q) exit 0 ;;
    esac
done