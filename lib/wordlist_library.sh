#!/bin/bash
# =============================================================================
# AskJohn - lib/wordlist_library.sh (The Librarian's Logic)
# =============================================================================

# Standardized path for the wordlist database
WORDLIST_INDEX="$BASE_DIR/lib/wordlists.db"

# --- FETCH ROCKYOU (GitHub) ---
fetch_famous_wordlist() {
    local url="https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
    local dest="$BASE_DIR/lib/rockyou.txt"

    if [[ -f "$dest" ]]; then
        echo -e "${YELLOW}The wordlist 'rockyou.txt' already exists.${NC}"
        return
    fi

    echo -e "${CYAN}Downloading rockyou.txt from GitHub...${NC}"
    curl -L "$url" -o "$dest"

    if [[ -f "$dest" ]]; then
        echo "$dest" >> "$WORDLIST_INDEX"
        sort -u "$WORDLIST_INDEX" -o "$WORDLIST_INDEX"
        echo -e "${GREEN}Wordlist added to database.${NC}"
    fi
}

# --- SCAN DIRECTORIES ---
scan_wordlists() {
    local search_path="$1"
    echo -e "${CYAN}Scanning: $search_path...${NC}"

    # Find .txt and .lst files, excluding the 'old' directory
    find "$search_path" -maxdepth 3 \( -name "*.txt" -o -name "*.lst" \) 2>/dev/null | grep -v "/old/" >> "$WORDLIST_INDEX"

    if [[ -f "$WORDLIST_INDEX" ]]; then
        sort -u "$WORDLIST_INDEX" -o "$WORDLIST_INDEX"
        echo -e "${GREEN}Scan complete. Database updated.${NC}"
    else
        echo -e "${RED}No wordlists found.${NC}"
    fi
}