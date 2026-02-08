#!/usr/bin/env bash
# AskJohn – config.example.sh
# Kopiere nach ../config.sh und passe Werte an – diese Datei wird committed!

JOHN_BIN=""                     # leer = Auto-Erkennung

WORDLIST_CANDIDATES=(
    "$HOME/wordlists/rockyou.txt"
    "$HOME/wordlists/rockyou.txt.gz"
    "/usr/share/wordlists/rockyou.txt"
    "/usr/share/wordlists/rockyou.txt.gz"
)

DEFAULT_HASH_FILE="hashes.txt"
SSH_TARGET=""                   # z.B. "user@192.168.1.100"
USE_COLORS=true
