#!/bin/bash
banner(){
    echo "**********************************"
    echo "* WELCOME TO THE CONNECT56       *"
    echo "* A TOOL TO CHECK IP INFORMATION *"
    echo "* AND BGP ROUTING INFO           *"
    echo "* CREATED BY EDEM ROBIN          *"
    echo "**********************************"
    echo
}
draw_line(){
    echo "----------------------------------------------------------"
}

table_row(){
    printf "| %-15s | %-40s |\n" "$1" "$2"
}

check_int_con(){
   #check if there is internet connection
   if ping -c 1 "8.8.8.8"  > /dev/null 2>&1;
   then
       echo "INTERNET AVAILABLE"
   else
      echo "NO INTERNET AVAILABLE"
      exit 1
   fi
}

what_is_my_ip(){
    ip=$(curl -s ifconfig.me)
    echo "Your PUblic IP address is: $ip"
}

ipinfo_check(){
    ipinfo=$(curl -s "ipinfo.io/$1")
    hostname=$(echo "$ipinfo" | jq -r '.hostname // "N/A"')
    asn=$(echo "$ipinfo" | jq -r ".org" | cut -d' ' -f1)
    company=$(echo "$ipinfo" | jq -r ".org" | cut -d' ' -f2-)
    city=$(echo "$ipinfo" | jq -r ".city")
    country=$(echo "$ipinfo" | jq -r ".country")
  #putting the result in a table
   draw_line
   table_row "FIELD" "VALUE"
   draw_line
   table_row "HOSTNAME" "$hostname"
   table_row "ASN" "$asn"
   table_row "ORG" "$company"
   table_row "CITY" "$city"
   table_row "COUNTRY" "$country"
   draw_line
}

whois_info(){
   data=$(whois "$1")

   #check if there is NetRange or inetnum in the whos db
   if echo "$data" | grep -q "NetRange";then
       netrange=$(echo "$data" | grep NetRange | awk -F ':' '{print $2}' | xargs)
       cidr=$(echo "$data" | grep CIDR  | awk -F ':' '{print $2}' | xargs)
       orgabusename=$(echo "$data" | grep OrgAbuseName | awk -F ':' '{print $2}' | xargs)
       orgabusephone=$(echo "$data" | grep OrgAbusePhone | awk -F ':' '{print $2}' | xargs)
       orgabuseemail=$(echo "$data" | grep OrgAbuseEmail | awk -F ':' '{print $3}' | xargs) 
      #putting the result in a table
      draw_line
      table_row "NETRANGE" "$netrange"
      table_row "CIDR" "$cidr"
      table_row "ABUSE NAME" "$orgabusename"
      table_row "ABUSE PHONE NUMBER" "$orgabusephone"
      table_row "ABUSE EMAIL" "$orgabuseemail"
      draw_line

  else 
      netrange=$(echo "$data" | grep inetnum | awk -F ':' '{print $2}' | xargs)
      parent=$(echo "$data" | grep parent | awk -F ':' '{print $2}' | xargs)
      country=$(echo "$data" | grep country | awk -F ':' '{print $2}' | xargs)
      #descr=$(echo "$data" | grep descr | awk -F ':' '{print $2}' | xargs)
       draw_line
       table_row "NETRANGE" "$netrange"
       table_row "PARENT" "$parent"
       table_row "COUNTRY" "$country"
       #table_tow "DESCRIPTION" "$descr"
       draw_line
  fi
}

bgp_info(){
     radb=$(whois -h whois.radb.net -- "-i origin $asn")
     routes=$(echo "$radb" | grep route | awk '{print $2}')
     rpk_status=$(echo "$radb" | grep "rpki-ov-state" | head -1 | awk '{print $2}')
     #rpk_status=$(echo "$radb" | grep rpki-ov-state | awk '{print $2}')
     #as_adv=$(echo "$routes" | wc -l)
     as_adv=$(echo "$radb" | grep "^route:" | wc -l)
     descr=$(echo "$radb" | grep descr | awk '{print $2}')

    #extral info
    draw_line
    table_row "ITEMS" "DETAILS INFO"
    draw_line
    table_row "ASN" "$asn"
    table_row "TOTAL PREFIX" "$as_adv"
    table_row "RPKI STATUS" "$rpk_status"
    draw_line
   
total=$(echo "$radb" | awk '/^route:/ {route=$2} /^descr:/ {print route " | " ($2 ? $2 : "N/A")}' | wc -l)

while IFS='|' read -r prefix desc; do
    table_row "$(echo "$prefix" | xargs)" "$(echo "$desc" | xargs)"
done < <(echo "$radb" | awk '/^route:/ {route=$2} /^descr:/ {print route " | " ($2 ? $2 : "N/A")}' | head -10)

if [ "$total" -gt 10 ]; then
    table_row "..." "showing first 10 of $total prefixes"
fi
draw_line
}

main(){
    ip=$1
    banner
    check_int_con
    echo
    draw_line
    what_is_my_ip
    draw_line
    #check if the user provided an ip address as an argument, if not ask for it
    if [ -z "$ip" ]; 
    then
         read -p "Enter ip address: " ip
    fi
    draw_line
    echo "|  IP INFORMATION FOR $ip  |"             
    draw_line
    ipinfo_check "$ip"
    whois_info "$ip"
    bgp_info
}

main
