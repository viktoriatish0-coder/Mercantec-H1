#!/bin/bash
# Script 7: AD-gruppe rapport (Mac версия)
# Formål: Lister medlemmer af alle sikkerhedsgrupper i Active Directory/lokale grupper.

EXPORT_PATH_AD="$HOME/Desktop/AD_GroupReport.csv"
RESULTS_FILE="$HOME/Desktop/group_members.tmp"

# Opretter CSV header
echo "Gruppenavn,Medarbejder,Brugernavn,GruppeType" > "$EXPORT_PATH_AD"

echo "Indsamler gruppe informationer..." >&2

# Metode 1: Henter lokale grupper fra macOS
if command -v dscacheutil &> /dev/null; then
    echo "Søger efter lokale grupper..." >&2
    
    # Henter liste over alle grupper
    dscacheutil -q group | grep "^name:" | awk '{print $NF}' | while read group; do
        # Henter medlemmer af gruppen
        members=$(dscacheutil -q group -a name "$group" | grep "^users:" | sed 's/users: //' | tr ',' '\n')
        
        if [ -n "$members" ]; then
            echo "$members" | while read member; do
                if [ -n "$member" ]; then
                    # Henter brugerinfo
                    uid=$(dscacheutil -q user -a name "$member" 2>/dev/null | grep "^uid:" | awk '{print $NF}')
                    if [ -n "$uid" ]; then
                        echo "$group,$member,$member,Local" >> "$EXPORT_PATH_AD"
                    fi
                fi
            done
        fi
    done
fi

# Metode 2: Henter grupper fra /etc/group (hvis tilgængelig)
if [ -f /etc/group ]; then
    echo "Søger efter system grupper fra /etc/group..." >&2
    
    grep -v "^#" /etc/group | grep -v "^_" | while IFS=: read group_name password gid members; do
        if [ -n "$members" ]; then
            # Splitter medlemmer ved komma
            echo "$members" | tr ',' '\n' | while read member; do
                if [ -n "$member" ]; then
                    echo "$group_name,$member,$member,System" >> "$EXPORT_PATH_AD"
                fi
            done
        fi
    done
fi

# Metode 3: Henter grupper via LDAP (hvis AD er tilsluttet)
if command -v ldapsearch &> /dev/null; then
    echo "Forsøger LDAP lookup..." >&2
    
    # Henter domæne info
    domain=$(dscacheutil -q group | grep "^name:" | head -1 | awk '{print $NF}')
    
    if [ -n "$domain" ]; then
        # Forsøger at søge efter grupper via LDAP
        ldapsearch -x -h localhost "(objectClass=groupOfNames)" cn member 2>/dev/null | \
        grep -E "^cn=|^member=" | paste -d, - - | \
        sed 's/cn=//g;s/member=//g' | while IFS=, read group member; do
            if [ -n "$group" ] && [ -n "$member" ]; then
                echo "$group,$member,$member,LDAP" >> "$EXPORT_PATH_AD"
            fi
        done
    fi
fi

# Metode 4: Henter grupper fra macOS Directory Services
if command -v dscl &> /dev/null; then
    echo "Søger efter Directory Services grupper..." >&2
    
    # Forsøger at hente grupper fra local node
    dscl /Local/Default -list /Groups 2>/dev/null | while read group; do
        # Henter GroupMembers
        members=$(dscl /Local/Default read "/Groups/$group" GroupMembers 2>/dev/null | tail -n +2 | tr '\n' ' ')
        
        if [ -n "$members" ]; then
            echo "$members" | tr ' ' '\n' | while read member; do
                if [ -n "$member" ]; then
                    echo "$group,$member,$member,DirectoryServices" >> "$EXPORT_PATH_AD"
                fi
            done
        fi
    done
fi

# Fjerner duplikater og sorterer
if [ -f "$EXPORT_PATH_AD" ]; then
    (head -1 "$EXPORT_PATH_AD"; tail -n +2 "$EXPORT_PATH_AD" | sort -u) > "$EXPORT_PATH_AD.tmp" 2>/dev/null
    mv "$EXPORT_PATH_AD.tmp" "$EXPORT_PATH_AD" 2>/dev/null || true
fi

# Output
echo ""
echo "========================================"
echo "AD Rapport er gemt i:"
echo "$EXPORT_PATH_AD"
echo "========================================"
echo ""
echo "Indhold af CSV-fil:"
cat "$EXPORT_PATH_AD"
echo ""
echo "I alt $(( $(wc -l < "$EXPORT_PATH_AD") - 1 )) gruppe medlemmer found"
