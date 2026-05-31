#!/bin/bash
# Script 3: Udtræk af DNS A-records (Mac версия)
# Formål: Eksporterer alle A-records fra DNS-zoner.

# Variabler
ZONE_NAME="techsolutions.local"
EXPORT_PATH_DNS="$HOME/Desktop/DNS_ARecords.csv"

# Opretter CSV header
echo "HostName,IPAddress,TTL,RecordType" > "$EXPORT_PATH_DNS"

echo "Indsamler DNS A-records..." >&2

# Metode 1: Henter fra /etc/hosts
if [ -f /etc/hosts ]; then
    grep -v "^#" /etc/hosts | grep -v "^$" | awk '{
        if (NF >= 2) {
            ip = $1
            for (i = 2; i <= NF; i++) {
                hostname = $i
                if (hostname != "localhost" && hostname !~ /^fe80|^::1|^255/) {
                    print hostname "," ip ",3600,A"
                }
            }
        }
    }' | sort -u >> "$EXPORT_PATH_DNS"
fi

# Metode 2: Henter fra nslookup (hvis tilgængelig)
if command -v nslookup &> /dev/null; then
    echo "Søger efter DNS records via nslookup..." >&2
    nslookup -type=A "$ZONE_NAME" 2>/dev/null | grep "Name:" | while read line; do
        hostname=$(echo "$line" | awk '{print $2}')
        if [ -n "$hostname" ]; then
            ip=$(nslookup "$hostname" 2>/dev/null | grep "^Address:" | tail -1 | awk '{print $NF}')
            if [ -n "$ip" ] && [ "$ip" != "Address:" ]; then
                echo "$hostname,$ip,3600,A" >> "$EXPORT_PATH_DNS"
            fi
        fi
    done 2>/dev/null
fi

# Metode 3: Henter fra DNS cache (scutil på macOS)
if command -v scutil &> /dev/null; then
    echo "Søger efter DNS cache..." >&2
    scutil --dns 2>/dev/null | grep -E "nameserver\[|search domain" | head -5 >> "$EXPORT_PATH_DNS" 2>/dev/null || true
fi

# Metode 4: Henter fra ARP table (bekræftede hosts på netværket)
if command -v arp &> /dev/null; then
    echo "Søger efter ARP records..." >&2
    arp -a 2>/dev/null | awk '{
        ip = $2
        gsub(/[()]/, "", ip)
        hostname = $1
        if (ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && hostname !~ /^\?/ && ip !~ /^127|^255/) {
            print hostname "," ip ",3600,A"
        }
    }' | sort -u >> "$EXPORT_PATH_DNS"
fi

# Fjerner duplikater og sorterer
if [ -f "$EXPORT_PATH_DNS" ]; then
    (head -1 "$EXPORT_PATH_DNS"; tail -n +2 "$EXPORT_PATH_DNS" | sort -u) > "$EXPORT_PATH_DNS.tmp" 2>/dev/null
    mv "$EXPORT_PATH_DNS.tmp" "$EXPORT_PATH_DNS" 2>/dev/null || true
fi

# Output
echo ""
echo "========================================"
echo "DNS A-records er eksporteret til:"
echo "$EXPORT_PATH_DNS"
echo "========================================"
echo ""
echo "Indhold af CSV-fil:"
cat "$EXPORT_PATH_DNS"
