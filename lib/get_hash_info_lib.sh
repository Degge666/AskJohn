#!/bin/bash
# =============================================================================
# AskJohn - lib/get_hash_info_lib.sh (The Identification Engine)
# =============================================================================

identify_hash_format() {
    local raw_hash="$1"
    local length=${#raw_hash}
    local results=()

    # Basic Identification Logic (Expandable)
    if [[ $raw_hash =~ ^\$6\$ ]]; then results+=("sha512crypt"); fi
    if [[ $raw_hash =~ ^\$1\$ ]]; then results+=("md5crypt"); fi
    if [[ $raw_hash =~ ^\$2[ayb]\$ ]]; then results+=("bcrypt"); fi

    # Length based identification
    case $length in
        32)  results+=("MD5" "NTLM") ;;
        40)  results+=("SHA-1") ;;
        64)  results+=("SHA-256") ;;
        128) results+=("SHA-512") ;;
    esac

    # Return results as a space-separated string
    if [ ${#results[@]} -eq 0 ]; then
        echo "Unknown"
    else
        echo "${results[@]}"
    fi
}

# Processes a file and creates the .info sidecar
analyze_artifact_file() {
    local target="$1"
    local info_file="${target}.info"

    echo -n "" > "$info_file" # Clear old wisdom

    # Read the first few lines to find types
    while read -r line; do
        [[ -z "$line" ]] && continue
        local found_types=$(identify_hash_format "$line")
        echo "$found_types" >> "$info_file"
    done < "$target"

    # Clean up: unique types only
    local unique_types=$(tr ' ' '\n' < "$info_file" | sort -u | tr '\n' ' ')
    echo "$unique_types" > "$info_file"
}