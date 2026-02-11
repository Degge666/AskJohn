#!/bin/bash
# =============================================================================
# AskJohn – lib/converters.sh (The Scavenger's Tools)
# =============================================================================

# Extract hash from a ZIP artifact
scavenge_zip() {
    local source_path="$1"
    local output_path="$2"
    # Logic: zip2john is called
    zip2john "$source_path" > "$output_path" 2>/dev/null
}

# Extract hash from a RAR artifact
scavenge_rar() {
    local source_path="$1"
    local output_path="$2"
    rar2john "$source_path" > "$output_path" 2>/dev/null
}

# Merge system shadow files (Linux)
scavenge_linux_shadow() {
    local output_path="$1"
    # Requires elevated privileges in the realm
    sudo unshadow /etc/passwd /etc/shadow > "$output_path"
}

# Dump Windows SAM/SYSTEM hives
scavenge_windows_sam() {
    local sys_hive="$1"
    local sam_hive="$2"
    local output_path="$3"
    samdump2 "$sys_hive" "$sam_hive" > "$output_path"
}