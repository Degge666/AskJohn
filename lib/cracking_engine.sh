#!/bin/bash
# --- THE ANCIENT SPELLS (Logic Only) ---

cast_wordlist_attack() {
    local target="$1"
    local wordlist="$2"
    local format="$3"
    # Führt nur den Befehl aus
    john ${format:+--format=$format} --wordlist="$wordlist" "$target"
}

cast_single_attack() {
    local target="$1"
    local format="$2"
    john ${format:+--format=$format} --single "$target"
}