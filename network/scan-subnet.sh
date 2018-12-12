SUBNET=${1?'Specify subnet in form of 192.168.59.0/24'}
nmap -sP "$SUBNET" | tr \\n \\t | sed 's:[[:space:]]\(Nmap scan report\):\n\1:g'
