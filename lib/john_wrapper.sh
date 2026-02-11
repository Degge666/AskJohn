#!/bin/bash
# =============================================================================
# AskJohn - lib/john_wrapper.sh (The Cracking Spells)
# =============================================================================

# Logic for Wordlist Attack
# @param 1: target_artifact (path to hash)
# @param 2: scroll_path (path to wordlist)
# @param 3: seal_format (optional john format)
execute_wordlist_spell() {
    local target="$1"
    local scroll="$2"
    local format="$3"

    # Constructing the raw command
    local cmd="john --wordlist=\"$scroll\" \"$target\""
    [[ -n "$format" ]] && cmd="john --format=\"$format\" --wordlist=\"$scroll\" \"$target\""

    # Use the dispatcher to cast the spell (handled in common.sh)
    invoke_spell "$cmd"
}

# Logic for Single Crack Mode
execute_single_spell() {
    local target="$1"
    local format="$2"
    local cmd="john --single \"$target\""
    [[ -n "$format" ]] && cmd="john --format=\"$format\" --single \"$target\""
    invoke_spell "$cmd"
}