#!/bin/bash
# =============================================================================
# AskJohn - lib/extract_hashes_lib.sh (The Extraction Engine)
# =============================================================================

# --- LOGIC: File Extraction ---
extract_from_file() {
    local source_file="$1"
    local filename=$(basename "$source_file")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local target_hash="$BASE_DIR/temp/${filename}_${timestamp}.hash"

    [[ ! -f "$source_file" ]] && return 1

    case "${filename,,}" in
        *.zip)               zip2john "$source_file" > "$target_hash" 2>/dev/null ;;
        *.rar)               rar2john "$source_file" > "$target_hash" 2>/dev/null ;;
        *.docx|*.xlsx|*.pptx) office2john "$source_file" > "$target_hash" 2>/dev/null ;;
        *.pdf)               pdf2john.pl "$source_file" > "$target_hash" 2>/dev/null ;;
        *) return 1 ;;
    esac

    # Return success if file is not empty
    [[ -s "$target_hash" ]] && echo "$target_hash" || rm -f "$target_hash"
}

# --- LOGIC: System Extraction (Unshadow) ---
extract_system_shadow() {
    local target_hash="$BASE_DIR/temp/system_unshadowed_$(date +%Y%m%d).hash"

    if [[ "$OS_TYPE" == "linux" || "$OS_TYPE" == "macos" ]]; then
        echo -e "${YELLOW}Requesting root powers to unshadow the realm...${NC}"
        sudo unshadow /etc/passwd /etc/shadow > "$target_hash" 2>/dev/null
    fi

    [[ -s "$target_hash" ]] && echo "$target_hash" || rm -f "$target_hash"
}