#!/bin/bash
# Script 2: Udtræk af leasede DHCP-adresser (Mac версия)
# Formål: Eksporterer aktive DHCP leases til en CSV-fil.

# Variabler, der nemt kan ændres i toppen af scriptet
EXPORT_PATH="$HOME/Desktop/DHCP_Leases.csv"
DHCP_CONFIG="/var/db/dhclient.leases"

# Opretter CSV header
echo "IPAddress,InterfaceAlias,LeaseStartTime,LeaseExpiryTime" > "$EXPORT_PATH"

# Henter DHCP info fra aktive netværksinterfacer
echo "Indsamler DHCP lease-informationer..." >&2

for interface in $(ifconfig | grep "^[a-z]" | awk '{print $1}' | sed 's/:$//'); do
    # Henter IP-adresse
    ip=$(ifconfig "$interface" 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
    
    if [ -n "$ip" ]; then
        # Henter DHCP lease info fra system
        lease_start=$(ipconfig getstatus "$interface" 2>/dev/null | grep "lease_start" | awk '{print $3}' || echo "N/A")
        lease_expiry=$(ipconfig getstatus "$interface" 2>/dev/null | grep "lease_expiry" | awk '{print $3}' || echo "N/A")
        
        # Hvis DHCP info ikke tilgængelig, prøver alternativ metode
        if [ "$lease_start" = "N/A" ]; then
            lease_start=$(date -u "+%Y-%m-%d %H:%M:%S")
            lease_expiry="Permanent"
        fi
        
        # Skriver til CSV
        echo "$ip,$interface,$lease_start,$lease_expiry" >> "$EXPORT_PATH"
    fi
done

# Henter DHCP leases fra dhclient.leases hvis tilgængelig
if [ -f "$DHCP_CONFIG" ]; then
    grep -E "^\s+lease|binding state|starts|ends" "$DHCP_CONFIG" | \
    awk 'BEGIN {RS="}"; FS="\n"} 
    {
        for(i=1; i<=NF; i++) {
            if($i ~ /lease/) ip=gensub(/.*lease ([0-9.]+).*/, "\\1", 1, $i)
            if($i ~ /starts/) starts=gensub(/.*starts ([^;]+);/, "\\1", 1, $i)
            if($i ~ /ends/) ends=gensub(/.*ends ([^;]+);/, "\\1", 1, $i)
        }
        if(ip) print ip "," "en0" "," starts "," ends
    }' >> "$EXPORT_PATH" 2>/dev/null
fi

# Output
echo ""
echo "========================================" 
echo "DHCP leases er gemt i: $EXPORT_PATH"
echo "========================================"
echo ""
echo "Indhold af CSV-fil:"
cat "$EXPORT_PATH"
