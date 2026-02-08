# AskJohn

Interactive Bash frontend / wrapper for **John the Ripper**  
Inspired by TryHackMe – John the Ripper Basics room

**Ziel**: Modular, sicher, cross-platform (macOS/Linux primär), mit klarer Trennung von Konfiguration und Code.

## Architektur (aktuell)

- `src/askjohn.sh`        → Hauptskript
- `examples/config.example.sh` → Vorlage (sicher committbar)
- `config.sh`              → Deine echte Konfiguration (gitignore-geschützt)

## Status

Phase 1: OS-Detection + Config-Laden + John-Prüfung

## Nächste Phasen (geplant)

- Wordlist-Suche (dynamisch)
- Hash-Input & Format-Detection
- Cracking-Modi (Wordlist / Single / Rules)
- Remote via SSH
- Error-Handling & Logging

