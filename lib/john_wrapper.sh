#!/bin/bash
# =============================================================================
# AskJohn - lib/john_wrapper.sh (The Spellbook)
# =============================================================================

# --- SPELL: Wordlist Attack ---
execute_wordlist_spell() {
    local target="$1"
    local wordlist="$2"
    local fmt="$3"

    print_header "CASTING WORDLIST SPELL"
    echo -e "Artifact: $(basename "$target")"
    echo -e "Scroll:   $(basename "$wordlist")"
    echo "------------------------------------------------"

    if [[ -n "$fmt" ]]; then
        $JOHN_PATH --format="$fmt" --wordlist="$wordlist" "$target"
    else
        $JOHN_PATH --wordlist="$wordlist" "$target"
    fi

    echo "------------------------------------------------"
    read -p "The echoes fade. Press Enter to return..."
}

# --- SPELL: Single Crack Mode ---
execute_single_spell() {
    local target="$1"
    local fmt="$2"
    print_header "CASTING LONE WOLF STRIKE"
    [[ -n "$fmt" ]] && $JOHN_PATH --format="$fmt" --single "$target" || $JOHN_PATH --single "$target"
    read -p "Press Enter..."
}

# --- SPELL: Ancient Rules (The Mangling) ---
execute_custom_rule_spell() {
    local target="$1"
    local rule_pattern="$2"
    local fmt="$3"

    local tmp_rule_file="$BASE_DIR/temp/custom_rule.conf"
    echo "[List.Rules:Custom]" > "$tmp_rule_file"
    echo "$rule_pattern" >> "$tmp_rule_file"

    print_header "CASTING ANCIENT RULES"
    echo -e "Pattern: $rule_pattern"
    echo "------------------------------------------------"

    if [[ -n "$fmt" ]]; then
        $JOHN_PATH --format="$fmt" --rules=Custom --config="$tmp_rule_file" "$target"
    else
        $JOHN_PATH --rules=Custom --config="$tmp_rule_file" "$target"
    fi

    rm "$tmp_rule_file"
    echo "------------------------------------------------"
    read -p "Rule strike complete. Press Enter..."
}

# --- SPELL: John Standard Rules ---
execute_john_standard_rules() {
    local target="$1"
    local fmt="$2"
    print_header "CASTING STANDARD RULES"
    [[ -n "$fmt" ]] && $JOHN_PATH --format="$fmt" --rules "$target" || $JOHN_PATH --rules "$target"
    read -p "Press Enter..."
}