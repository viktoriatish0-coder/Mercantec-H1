#!/bin/bash
# Script 1: Serverinfo-rapport (Mac версия)
# Formål: Viser OS, seneste opdatering, netværk og kørende services.

echo "=== OS Information ===" 
# Henter OS info
echo "OS Navn: $(sw_vers -productName)"
echo "Version: $(sw_vers -productVersion)"
echo "Build: $(sw_vers -buildVersion)"

echo ""
echo "=== Seneste System Update ==="
# Henter sidste software update
softwareupdate -l 2>/dev/null | head -5 || echo "Ingen updates tilgængelige"

echo ""
echo "=== Netværkskonfiguration ==="
# Henter netværk info
ifconfig | grep -E "^[a-z]|inet " | grep -B1 "inet " | grep -v "inet 127"

echo ""
echo "=== Kørende Services ==="
# Henter alle kørende processer (top 10)
ps aux | head -11 | awk '{printf "%-10s %-5s %-5s %s\n", $1, $2, $3, $11}' | sort
