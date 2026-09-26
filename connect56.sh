#!/usr/bin/env bash
# ==============================================================================
# CONNECT56 - Production Cyber Security & Network Intelligence CLI Tool
# Author: Edem Robin
# License: MIT
# Description: Advanced IP / Domain threat intelligence, WHOIS, DNS PTR/Enum,
#              Web Recon, Subdomain Discovery (Alive/Dead), and BGP routing lookup
# ==============================================================================

set -euo pipefail

# Script Version
VERSION="2.0.0"

# Colors & Formatting (Default enabled if terminal attached)
if [[ -t 1 ]]; then
    COLOR_ENABLED=true
else
    COLOR_ENABLED=false
fi

JSON_MODE=false
QUIET_MODE=false
TARGET=""
SELECTED_MODULES="ALL" # Default to all modules

# Color definitions
init_colors() {
    if [[ "$COLOR_ENABLED" == true ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        RESET='\033[0m'
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        MAGENTA=''
        CYAN=''
        BOLD=''
        RESET=''
    fi
}

show_version() {
    echo -e "CONNECT56 Network Intelligence Tool v${VERSION}"
}

show_help() {
    cat << EOF
CONNECT56 - Cyber Security & Network Intelligence CLI Tool v${VERSION}

USAGE:
    ./connect56.sh [OPTIONS] [IP_ADDRESS | DOMAIN]

DESCRIPTION:
    CONNECT56 inspects IPv4/IPv6 addresses or domains to gather threat intelligence,
    DNS records, Web technology fingerprints, Subdomains (Alive vs Dead),
    network ownership (WHOIS/RDAP), ASN, and BGP routing data.

OPTIONS:
    -j, --json        Output result in JSON format (ideal for SIEM/pipelines)
    -c, --no-color    Disable ANSI colorized output
    -q, --quiet       Suppress headers and non-essential logs
    -u, --update      Check GitHub for updates and self-update
    -m, --modules     Specify modules to run (comma-separated: all,whois,dns,web,subdomain)
    -v, --version     Show tool version
    -h, --help        Show this help message
    -l, --lan-scan     Scan the local network for devices and open ports

EXAMPLES:
    ./connect56.sh 8.8.8.8
    ./connect56.sh example.com --json
    ./connect56.sh example.com --modules dns,subdomain
    ./connect56.sh --update

EOF
}

# Self-update function
check_and_update() {
    log_info "Checking GitHub repository for CONNECT56 updates..."
    local repo_url="https://raw.githubusercontent.com/kojoedem/connect56/main/connect56.sh"
    local remote_version
    remote_version=$(curl -s --connect-timeout 5 "$repo_url" 2>/dev/null | grep -E '^VERSION=' | head -n1 | cut -d'"' -f2 || echo "")

    if [[ -z "$remote_version" ]]; then
        log_warn "Unable to fetch remote version from GitHub. Please check your internet connection or repository URL."
        return 1
    fi

    if [[ "$remote_version" != "$VERSION" ]]; then
        log_success "New version available: v${remote_version} (Current: v${VERSION})"
        echo -n "Would you like to update now? [y/N]: "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Downloading latest connect56.sh from GitHub..."
            local tmp_script
            tmp_script=$(mktemp)
            if curl -s -L "$repo_url" -o "$tmp_script" && grep -q 'VERSION=' "$tmp_script"; then
                chmod +x "$tmp_script"
                mv "$tmp_script" "$0"
                log_success "CONNECT56 successfully updated to v${remote_version}!"
                exit 0
            else
                log_error "Failed to download valid update script."
                rm -f "$tmp_script"
                return 1
            fi
        fi
    else
        log_success "CONNECT56 is already up to date (v${VERSION})."
    fi
}
run_lan_scan() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lan_script="${script_dir}/lan_scan.sh"

    if [[ ! -f "$lan_script" ]]; then
        log_error "lan_scan.sh not found in ${script_dir}. Place it in the same folder as connect56.sh."
        exit 1
    fi

    [[ -x "$lan_script" ]] || chmod +x "$lan_script"

    log_info "Launching LAN scan module..."
    "$lan_script" "$@"
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json)
                JSON_MODE=true
                shift
                ;;
            -c|--no-color)
                COLOR_ENABLED=false
                shift
                ;;
            -q|--quiet)
                QUIET_MODE=true
                shift
                ;;
            -u|--update)
                check_and_update
                exit 0
                ;;
            -m|--modules)
                SELECTED_MODULES="$2"
                shift 2
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--lan-scan)
                shift
                run_lan_scan "$@"
                exit 0
                ;;
            -*)
                echo -e "Error: Unknown option '$1'" >&2
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$TARGET" ]]; then
                    TARGET="$1"
                else
                    echo -e "Error: Unexpected argument '$1'" >&2
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

banner() {
    if [[ "$QUIET_MODE" == true || "$JSON_MODE" == true ]]; then
        return
    fi
    echo -e "${CYAN}${BOLD}**********************************************************${RESET}"
    echo -e "${CYAN}${BOLD}*                     CONNECT56 v2.0                     *${RESET}"
    echo -e "${CYAN}${BOLD}*   Production Cyber Security & Network Intelligence Tool *${RESET}"
    echo -e "${CYAN}${BOLD}*                 Created by Edem Robin                  *${RESET}"
    echo -e "${CYAN}${BOLD}**********************************************************${RESET}\n"
}

log_info() {
    if [[ "$QUIET_MODE" == false && "$JSON_MODE" == false ]]; then
        echo -e "${BLUE}[*]${RESET} $1" >&2
    fi
}

log_success() {
    if [[ "$QUIET_MODE" == false && "$JSON_MODE" == false ]]; then
        echo -e "${GREEN}[+]${RESET} $1" >&2
    fi
}

log_warn() {
    if [[ "$QUIET_MODE" == false && "$JSON_MODE" == false ]]; then
        echo -e "${YELLOW}[!]${RESET} $1" >&2
    fi
}

log_error() {
    if [[ "$JSON_MODE" == false ]]; then
        echo -e "${RED}[-] Error:${RESET} $1" >&2
    fi
}

draw_line() {
    if [[ "$JSON_MODE" == true ]]; then return; fi
    echo -e "${CYAN}+-----------------+---------------------------------------------------------+${RESET}"
}

table_row() {
    if [[ "$JSON_MODE" == true ]]; then return; fi
    local key="$1"
    local val="$2"
    printf "${CYAN}|${RESET} %-15s ${CYAN}|${RESET} %-55s ${CYAN}|${RESET}\n" "$key" "${val:0:55}"
}

prompt_module_selection() {
    if [[ "$JSON_MODE" == true || "$QUIET_MODE" == true ]]; then
        return
    fi

    # Interactive module menu if interactive session and not explicitly passed via flag
    if [[ -t 0 && "$SELECTED_MODULES" == "ALL" ]]; then
        echo -e "${BOLD}Select Intelligence Modules to Run:${RESET}"
        echo -e "  ${CYAN}[1]${RESET} Run ALL Intelligence Modules (Full Scan)"
        echo -e "  ${CYAN}[2]${RESET} Network Overview, WHOIS & BGP Routing Only"
        echo -e "  ${CYAN}[3]${RESET} DNS Record Enumeration (A, AAAA, NS, MX, TXT)"
        echo -e "  ${CYAN}[4]${RESET} Web Technology & Header Reconnaissance"
        echo -e "  ${CYAN}[5]${RESET} Subdomain Discovery & Health Check (Alive vs Dead)"
        echo -e "  ${CYAN}[6]${RESET} Custom Module Selection"
        # echo -e "  ${CYAN}[7]${RESET} Check GitHub for Script Updates"
        # echo
        # read -rp "Enter choice [1-7] (Default: 1): " module_choice
        # case "$module_choice" in
        #     2) SELECTED_MODULES="WHOIS" ;;
        #     3) SELECTED_MODULES="DNS" ;;
        #     4) SELECTED_MODULES="WEB" ;;
        #     5) SELECTED_MODULES="SUBDOMAIN" ;;
        #     6)
        #         read -rp "Enter comma-separated modules (whois,dns,web,subdomain): " custom_mods
        #         SELECTED_MODULES="$custom_mods"
        #         ;;
        #     7)
        #         check_and_update
        #         exit 0
        #         ;;
        #     *) SELECTED_MODULES="ALL" ;;
        # esac
        echo -e "  ${CYAN}[7]${RESET} Check GitHub for Script Updates"
        echo -e "  ${CYAN}[8]${RESET} Local Area Network Scan (devices & open ports)"
        echo
        read -rp "Enter choice [1-8] (Default: 1): " module_choice
        case "$module_choice" in
            2) SELECTED_MODULES="WHOIS" ;;
            3) SELECTED_MODULES="DNS" ;;
            4) SELECTED_MODULES="WEB" ;;
            5) SELECTED_MODULES="SUBDOMAIN" ;;
            6)
                read -rp "Enter comma-separated modules (whois,dns,web,subdomain): " custom_mods
                SELECTED_MODULES="$custom_mods"
                ;;
            7)
                check_and_update
                exit 0
                ;;
            8)
                run_lan_scan
                exit 0
                ;;
            *) SELECTED_MODULES="ALL" ;;
        esac
        echo
    fi
}

should_run_module() {
    local mod="$1"
    local upper_selected
    upper_selected=$(echo "$SELECTED_MODULES" | tr '[:lower:]' '[:upper:]')
    if [[ "$upper_selected" == "ALL" || "$upper_selected" == "1" || "$upper_selected" =~ "$mod" ]]; then
        return 0
    else
        return 1
    fi
}

check_internet_connection() {
    log_info "Checking internet connectivity..."
    if ping -c 1 -W 2 "8.8.8.8" >/dev/null 2>&1 || ping -c 1 -W 2 "1.1.1.1" >/dev/null 2>&1 || curl -s --connect-timeout 3 https://1.1.1.1 >/dev/null 2>&1; then
        log_success "Internet connection available."
    else
        log_error "No internet connectivity detected."
        exit 1
    fi
}

get_my_public_ip() {
    local my_ip=""
    my_ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 api.ipify.org 2>/dev/null || curl -s --connect-timeout 5 icanhazip.com 2>/dev/null || echo "Unknown")
    my_ip=$(echo "$my_ip" | xargs)
    if [[ "$JSON_MODE" == false && "$QUIET_MODE" == false ]]; then
        echo -e "${BOLD}Your Public IP Address:${RESET} ${GREEN}${my_ip}${RESET}"
    fi
}

# Input validation helpers
is_valid_ipv4() {
    local ip="$1"
    local rx='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    if [[ $ip =~ $rx ]]; then
        local OIFS=$IFS
        IFS='.'
        read -r -a octets <<< "$ip"
        IFS=$OIFS
        [[ ${octets[0]} -le 255 && ${octets[1]} -le 255 && ${octets[2]} -le 255 && ${octets[3]} -le 255 ]]
    else
        return 1
    fi
}

is_valid_ipv6() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]
}

is_private_ip() {
    local ip="$1"
    # IPv4 Private / Loopback / Link-Local / CGNAT / Multicast / Reserved
    if is_valid_ipv4 "$ip"; then
        if [[ "$ip" =~ ^127\. ]] || \
           [[ "$ip" =~ ^10\. ]] || \
           [[ "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || \
           [[ "$ip" =~ ^192\.168\. ]] || \
           [[ "$ip" =~ ^169\.254\. ]] || \
           [[ "$ip" =~ ^100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\. ]] || \
           [[ "$ip" =~ ^22[4-9]\. ]] || \
           [[ "$ip" =~ ^23[0-9]\. ]] || \
           [[ "$ip" =~ ^0\. ]]; then
            return 0
        fi
    elif is_valid_ipv6 "$ip"; then
        local lower_ip
        lower_ip=$(echo "$ip" | tr '[:upper:]' '[:lower:]')
        if [[ "$lower_ip" == "::1" || "$lower_ip" =~ ^fe80: || "$lower_ip" =~ ^fc00: || "$lower_ip" =~ ^fd00: ]]; then
            return 0
        fi
    fi
    return 1
}

resolve_domain() {
    local query="$1"
    local resolved=""
    if command -v dig >/dev/null 2>&1; then
        resolved=$(dig +short A "$query" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 || true)
        if [[ -z "$resolved" ]]; then
            resolved=$(dig +short AAAA "$query" 2>/dev/null | head -n1 || true)
        fi
    elif command -v nslookup >/dev/null 2>&1; then
        resolved=$(nslookup "$query" 2>/dev/null | awk '/^Address: / {print $2}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 || true)
    elif command -v host >/dev/null 2>&1; then
        resolved=$(host -t A "$query" 2>/dev/null | awk '/has address/ {print $4}' | head -n1 || true)
        if [[ -z "$resolved" ]]; then
            resolved=$(host -t AAAA "$query" 2>/dev/null | awk '/has IPv6 address/ {print $5}' | head -n1 || true)
        fi
    fi

    if [[ -z "$resolved" ]] && command -v python3 >/dev/null 2>&1; then
        resolved=$(python3 -c "import socket; print(socket.gethostbyname('$query'))" 2>/dev/null || true)
    fi

    echo "$resolved"
}

get_ptr_record() {
    local ip="$1"
    local ptr=""
    if command -v dig >/dev/null 2>&1; then
        ptr=$(dig +short -x "$ip" 2>/dev/null | sed 's/\.$//' | head -n1 || true)
    elif command -v nslookup >/dev/null 2>&1; then
        ptr=$(nslookup "$ip" 2>/dev/null | awk -F'name = ' '/name =/ {print $2}' | sed 's/\.$//' | head -n1 || true)
    elif command -v host >/dev/null 2>&1; then
        ptr=$(host "$ip" 2>/dev/null | awk '/domain name pointer/ {print $5}' | sed 's/\.$//' | head -n1 || true)
    fi
    if [[ -z "$ptr" ]]; then
        ptr="N/A"
    fi
    echo "$ptr"
}

fetch_ip_intel() {
    local target="$1"
    local res=""

    res=$(curl -s --connect-timeout 5 "https://ipinfo.io/${target}/json" 2>/dev/null || true)
    if [[ -n "$res" && $(echo "$res" | jq -r '.ip // empty' 2>/dev/null) != "" ]]; then
        echo "$res"
        return
    fi

    res=$(curl -s --connect-timeout 5 "https://ipapi.co/${target}/json/" 2>/dev/null || true)
    if [[ -n "$res" && $(echo "$res" | jq -r '.ip // empty' 2>/dev/null) != "" ]]; then
        local ip hostname asn org city country
        ip=$(echo "$res" | jq -r '.ip // "N/A"')
        hostname=$(echo "$res" | jq -r '.hostname // "N/A"')
        asn=$(echo "$res" | jq -r '.asn // "N/A"')
        org=$(echo "$res" | jq -r '.org // "N/A"')
        city=$(echo "$res" | jq -r '.city // "N/A"')
        country=$(echo "$res" | jq -r '.country_name // "N/A"')
        jq -n --arg ip "$ip" --arg hostname "$hostname" --arg org "$asn $org" --arg city "$city" --arg country "$country" \
            '{ip: $ip, hostname: $hostname, org: $org, city: $city, country: $country}'
        return
    fi

    echo "{}"
}

fetch_whois_data() {
    local target="$1"
    local netrange="N/A"
    local cidr="N/A"
    local abuse_name="N/A"
    local abuse_email="N/A"
    local abuse_phone="N/A"
    local org_name="N/A"

    if command -v whois >/dev/null 2>&1; then
        local raw_whois
        raw_whois=$(whois "$target" 2>/dev/null || true)

        if [[ -n "$raw_whois" ]]; then
            netrange=$(echo "$raw_whois" | grep -iE '^(NetRange|inetnum):' | head -n1 | awk -F':' '{print $2}' | xargs || echo "N/A")
            cidr=$(echo "$raw_whois" | grep -iE '^(CIDR|route):' | head -n1 | awk -F':' '{print $2}' | xargs || echo "N/A")
            org_name=$(echo "$raw_whois" | grep -iE '^(Organization|OrgName|owner|descr):' | head -n1 | awk -F':' '{print $2}' | xargs || echo "N/A")
            abuse_email=$(echo "$raw_whois" | grep -iE '^(OrgAbuseEmail|abuse-mailbox):' | head -n1 | awk -F':' '{print $2}' | xargs || echo "N/A")
            abuse_phone=$(echo "$raw_whois" | grep -iE '^(OrgAbusePhone|phone):' | head -n1 | awk -F':' '{print $2}' | xargs || echo "N/A")
            abuse_name=$(echo "$raw_whois" | grep -iE '^(OrgAbuseName|person):' | head -n1 | awk -F':' '{print $2}' | xargs || echo "N/A")
        fi
    fi

    # RDAP Fallback if whois produced missing data
    if [[ "$netrange" == "N/A" || -z "$netrange" ]]; then
        local rdap_json
        rdap_json=$(curl -s --connect-timeout 5 "https://rdap.org/ip/${target}" 2>/dev/null || true)
        if [[ -n "$rdap_json" ]]; then
            cidr=$(echo "$rdap_json" | jq -r '.cidr0_cidrs[0] | (.v4prefix // .v6prefix) + "/" + (.length|tostring)' 2>/dev/null || echo "N/A")
            org_name=$(echo "$rdap_json" | jq -r '.name // "N/A"' 2>/dev/null || echo "N/A")
            netrange=$(echo "$rdap_json" | jq -r '.startAddress + " - " + .endAddress' 2>/dev/null || echo "N/A")
        fi
    fi

    jq -n \
        --arg netrange "${netrange:-N/A}" \
        --arg cidr "${cidr:-N/A}" \
        --arg org "${org_name:-N/A}" \
        --arg abuse_name "${abuse_name:-N/A}" \
        --arg abuse_email "${abuse_email:-N/A}" \
        --arg abuse_phone "${abuse_phone:-N/A}" \
        '{netrange: $netrange, cidr: $cidr, org: $org, abuse_name: $abuse_name, abuse_email: $abuse_email, abuse_phone: $abuse_phone}'
}

fetch_bgp_data() {
    local asn="$1"
    local total_prefix=0
    local rpki_status="N/A"
    local sample_prefixes=()

    local asn_num
    asn_num=$(echo "$asn" | grep -oE '[0-9]+' || true)

    if [[ -z "$asn_num" ]]; then
        jq -n --arg asn "N/A" --arg total 0 --arg rpki "N/A" --argjson prefixes "[]" \
            '{asn: $asn, total_prefixes: ($total|tonumber), rpki_status: $rpki, sample_prefixes: $prefixes}'
        return
    fi

    local ripe_bgp
    ripe_bgp=$(curl -s --connect-timeout 5 "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS${asn_num}" 2>/dev/null || true)

    if [[ -n "$ripe_bgp" && $(echo "$ripe_bgp" | jq -r '.status // empty' 2>/dev/null) == "ok" ]]; then
        total_prefix=$(echo "$ripe_bgp" | jq -r '.data.prefixes | length' 2>/dev/null || echo 0)
        mapfile -t sample_prefixes < <(echo "$ripe_bgp" | jq -r '.data.prefixes[0:10][].prefix' 2>/dev/null || true)
        rpki_status="valid (RIPE Stat)"
    elif command -v whois >/dev/null 2>&1; then
        local radb
        radb=$(whois -h whois.radb.net -- "-i origin AS${asn_num}" 2>/dev/null || true)
        if [[ -n "$radb" ]]; then
            total_prefix=$(echo "$radb" | grep -c "^route:" || true)
            rpki_status=$(echo "$radb" | grep -i "rpki-ov-state" | head -n1 | awk '{print $2}' || echo "N/A")
            mapfile -t sample_prefixes < <(echo "$radb" | grep "^route:" | head -n10 | awk '{print $2}' || true)
        fi
    fi

    local prefixes_json
    prefixes_json=$(printf '%s\n' "${sample_prefixes[@]}" | jq -R . | jq -s .)

    jq -n \
        --arg asn "AS${asn_num}" \
        --arg total "$total_prefix" \
        --arg rpki "${rpki_status:-N/A}" \
        --argjson prefixes "$prefixes_json" \
        '{asn: $asn, total_prefixes: ($total|tonumber), rpki_status: $rpki, sample_prefixes: $prefixes}'
}

# DNS Enumeration Module
fetch_dns_records() {
    local target_domain="$1"
    local ns_recs=() mx_recs=() txt_recs=() a_recs=() aaaa_recs=()

    if command -v dig >/dev/null 2>&1; then
        mapfile -t ns_recs < <(dig +short NS "$target_domain" 2>/dev/null | sed 's/\.$//' || true)
        mapfile -t mx_recs < <(dig +short MX "$target_domain" 2>/dev/null | sed 's/\.$//' || true)
        mapfile -t txt_recs < <(dig +short TXT "$target_domain" 2>/dev/null || true)
        mapfile -t a_recs < <(dig +short A "$target_domain" 2>/dev/null || true)
        mapfile -t aaaa_recs < <(dig +short AAAA "$target_domain" 2>/dev/null || true)
    elif command -v nslookup >/dev/null 2>&1; then
        mapfile -t ns_recs < <(nslookup -type=NS "$target_domain" 2>/dev/null | awk -F'nameserver = ' '/nameserver =/ {print $2}' | sed 's/\.$//' || true)
        mapfile -t mx_recs < <(nslookup -type=MX "$target_domain" 2>/dev/null | awk -F'mail exchanger = ' '/mail exchanger =/ {print $2}' | sed 's/\.$//' || true)
        mapfile -t txt_recs < <(nslookup -type=TXT "$target_domain" 2>/dev/null | awk -F'text = ' '/text =/ {print $2}' || true)
        mapfile -t a_recs < <(nslookup -type=A "$target_domain" 2>/dev/null | awk '/^Address: / {print $2}' || true)
        mapfile -t aaaa_recs < <(nslookup -type=AAAA "$target_domain" 2>/dev/null | awk '/^Address: / {print $2}' || true)
    fi

    jq -n \
        --argjson ns "$(printf '%s\n' "${ns_recs[@]}" | jq -R . | jq -s .)" \
        --argjson mx "$(printf '%s\n' "${mx_recs[@]}" | jq -R . | jq -s .)" \
        --argjson txt "$(printf '%s\n' "${txt_recs[@]}" | jq -R . | jq -s .)" \
        --argjson a "$(printf '%s\n' "${a_recs[@]}" | jq -R . | jq -s .)" \
        --argjson aaaa "$(printf '%s\n' "${aaaa_recs[@]}" | jq -R . | jq -s .)" \
        '{NS: $ns, MX: $mx, TXT: $txt, A: $a, AAAA: $aaaa}'
}

# Web Reconnaissance & Fingerprinting Module
fetch_web_recon() {
    local target="$1"
    local url="http://${target}"

    local headers_tmp html_tmp
    headers_tmp=$(mktemp)
    html_tmp=$(mktemp)

    local http_code server powered_by title redirect_url

    # Perform curl request with 5s timeout
    curl -s -L -D "$headers_tmp" --max-time 5 "$url" -o "$html_tmp" 2>/dev/null || true

    http_code=$(grep -i '^HTTP/' "$headers_tmp" | tail -n1 | awk '{print $2}' || echo "N/A")
    server=$(grep -i '^Server:' "$headers_tmp" | tail -n1 | cut -d':' -f2- | tr -d '\r\n' | xargs || echo "N/A")
    powered_by=$(grep -i '^X-Powered-By:' "$headers_tmp" | tail -n1 | cut -d':' -f2- | tr -d '\r\n' | xargs || echo "N/A")
    redirect_url=$(grep -i '^Location:' "$headers_tmp" | tail -n1 | cut -d':' -f2- | tr -d '\r\n' | xargs || echo "N/A")

    if [[ -s "$html_tmp" ]]; then
        title=$(grep -ioP '(?<=<title>)(.*?)(?=</title>)' "$html_tmp" | head -n1 | tr -d '\n\r' | xargs || echo "N/A")
    fi

    rm -f "$headers_tmp" "$html_tmp"

    jq -n \
        --arg http_code "${http_code:-N/A}" \
        --arg server "${server:-N/A}" \
        --arg powered_by "${powered_by:-N/A}" \
        --arg redirect "${redirect_url:-N/A}" \
        --arg title "${title:-N/A}" \
        '{http_status: $http_code, server: $server, x_powered_by: $powered_by, redirect_url: $redirect, page_title: $title}'
}

# Subdomain Enumeration Module (CRT.sh + Resolution Check -> Alive/Dead)
fetch_subdomains() {
    local domain="$1"
    local alive_subs=()
    local dead_subs=()

    log_info "Querying certificate transparency logs (crt.sh) for subdomains of $domain..."
    local crt_json
    crt_json=$(curl -s --connect-timeout 8 "https://crt.sh/?q=%.${domain}&output=json" 2>/dev/null || true)

    local raw_subdomains=()
    if [[ -n "$crt_json" && "$crt_json" =~ ^\[ ]]; then
        mapfile -t raw_subdomains < <(echo "$crt_json" | jq -r '.[].name_value' 2>/dev/null | tr '\n' ' ' | tr ' ' '\n' | sed 's/\*\.//g' | awk -F'@' '{print $NF}' | tr -d '\r\\' | grep -iE "^[a-zA-Z0-9.-]+\.${domain}$" | sort -u || true)
    fi

    # Common subdomains fallback list if crt.sh returns few/no results
    if [[ ${#raw_subdomains[@]} -lt 3 ]]; then
        local common_list=("www" "mail" "remote" "blog" "webmail" "server" "ns1" "ns2" "smtp" "secure" "vpn" "api" "dev" "portal" "admin" "m" "app" "shop")
        for sub in "${common_list[@]}"; do
            raw_subdomains+=("${sub}.${domain}")
        done
    fi

    # Deduplicate candidate subdomains and check top 20 max to avoid long delays
    mapfile -t unique_subs < <(printf '%s\n' "${raw_subdomains[@]}" | sort -u | head -n 20 || true)

    log_info "Probing ${#unique_subs[@]} candidate subdomains for DNS resolution status (Alive vs Dead)..."

    for sub in "${unique_subs[@]}"; do
        [[ -z "$sub" ]] && continue
        local sub_ip
        sub_ip=$(resolve_domain "$sub")
        if [[ -n "$sub_ip" ]]; then
            alive_subs+=("${sub}|${sub_ip}")
        else
            dead_subs+=("${sub}|UNRESOLVED")
        fi
    done

    # Build JSON lists
    local alive_json dead_json
    alive_json=$(printf '%s\n' "${alive_subs[@]}" | jq -R . | jq -s .)
    dead_json=$(printf '%s\n' "${dead_subs[@]}" | jq -R . | jq -s .)

    jq -n \
        --argjson alive "$alive_json" \
        --argjson dead "$dead_json" \
        '{alive_subdomains: $alive, dead_subdomains: $dead}'
}

main() {
    init_colors
    parse_args "$@"

    banner
    check_internet_connection
    get_my_public_ip

    # Prompt user if target not provided
    if [[ -z "$TARGET" ]]; then
        if [[ "$JSON_MODE" == true ]]; then
            echo '{"error": "Target IP or domain is required"}' >&2
            exit 1
        fi
        echo
        read -rp "Enter IP address or Domain to inspect: " TARGET
    fi

    TARGET=$(echo "$TARGET" | xargs)

    if [[ -z "$TARGET" ]]; then
        log_error "No target specified."
        exit 1
    fi

    prompt_module_selection

    local target_ip="$TARGET"
    local original_domain=""

    if ! is_valid_ipv4 "$TARGET" && ! is_valid_ipv6 "$TARGET"; then
        log_info "Resolving domain '$TARGET'..."
        resolved_ip=$(resolve_domain "$TARGET")
        if [[ -n "$resolved_ip" ]]; then
            original_domain="$TARGET"
            target_ip="$resolved_ip"
            log_success "Domain '$TARGET' resolved to IP: $target_ip"
        else
            log_error "Could not resolve domain '$TARGET' to a valid IP address."
            exit 1
        fi
    else
        # Target was an IP directly, try reverse DNS to find domain context
        local ptr_find
        ptr_find=$(get_ptr_record "$TARGET")
        if [[ "$ptr_find" != "N/A" ]]; then
            original_domain="$ptr_find"
        fi
    fi

    local is_private=false
    if is_private_ip "$target_ip"; then
        is_private=true
        log_warn "Target '$target_ip' is a Private/Internal/Bogon IP address (RFC 1918 / Loopback / Link-Local)."
    fi

    local ptr_record="N/A"
    ptr_record=$(get_ptr_record "$target_ip")

    local ipinfo_data="{}"
    local whois_data="{}"
    local bgp_data="{}"
    local dns_data="{}"
    local web_data="{}"
    local subdomains_data="{}"

    if [[ "$is_private" == false ]]; then
        if should_run_module "WHOIS"; then
            log_info "Gathering IP intelligence for $target_ip..."
            ipinfo_data=$(fetch_ip_intel "$target_ip")

            log_info "Gathering WHOIS & RDAP data..."
            whois_data=$(fetch_whois_data "$target_ip")

            local asn
            asn=$(echo "$ipinfo_data" | jq -r '.org // ""' | grep -oE 'AS[0-9]+' | head -n1 || true)
            if [[ -n "$asn" ]]; then
                log_info "Gathering BGP Routing information for $asn..."
                bgp_data=$(fetch_bgp_data "$asn")
            else
                bgp_data=$(jq -n '{asn: "N/A", total_prefixes: 0, rpki_status: "N/A", sample_prefixes: []}')
            fi
        fi

        local search_domain="${original_domain:-$TARGET}"

        if should_run_module "DNS" && [[ -n "$search_domain" ]]; then
            log_info "Enumerating DNS Records for $search_domain..."
            dns_data=$(fetch_dns_records "$search_domain")
        fi

        if should_run_module "WEB"; then
            log_info "Running Web Reconnaissance for $TARGET..."
            web_data=$(fetch_web_recon "$TARGET")
        fi

        if should_run_module "SUBDOMAIN" && [[ -n "$search_domain" ]] && ! is_valid_ipv4 "$search_domain"; then
            log_info "Enumerating Subdomains for $search_domain..."
            subdomains_data=$(fetch_subdomains "$search_domain")
        fi
    fi

    # JSON Output Mode
    if [[ "$JSON_MODE" == true ]]; then
        jq -n \
            --arg target "$TARGET" \
            --arg ip "$target_ip" \
            --arg domain "${original_domain:-N/A}" \
            --arg is_priv "$is_private" \
            --arg ptr "$ptr_record" \
            --argjson ipinfo "$ipinfo_data" \
            --argjson whois "$whois_data" \
            --argjson bgp "$bgp_data" \
            --argjson dns "$dns_data" \
            --argjson web "$web_data" \
            --argjson subdomains "$subdomains_data" \
            '{
                target: $target,
                ip: $ip,
                domain: $domain,
                is_private: ($is_priv == "true"),
                ptr_record: $ptr,
                ip_intelligence: $ipinfo,
                whois_rdap: $whois,
                bgp_routing: $bgp,
                dns_enumeration: $dns,
                web_reconnaissance: $web,
                subdomains: $subdomains
            }'
        exit 0
    fi

    # Display Standard Human-Readable Table Output
    echo
    echo -e "${BOLD}${MAGENTA}=================== TARGET SUMMARY: $target_ip ===================${RESET}"
    draw_line
    table_row "TARGET" "$TARGET"
    table_row "RESOLVED IP" "$target_ip"
    table_row "PTR (REVERSE DNS)" "$ptr_record"
    table_row "IS PRIVATE/BOGON" "$is_private"

    if should_run_module "WHOIS" && [[ "$is_private" == false ]]; then
        local hostname org city country
        hostname=$(echo "$ipinfo_data" | jq -r '.hostname // "N/A"')
        org=$(echo "$ipinfo_data" | jq -r '.org // "N/A"')
        city=$(echo "$ipinfo_data" | jq -r '.city // "N/A"')
        country=$(echo "$ipinfo_data" | jq -r '.country // "N/A"')
        table_row "HOSTNAME" "$hostname"
        table_row "ASN & ORG" "$org"
        table_row "LOCATION" "$city, $country"
    fi
    draw_line

    if should_run_module "WHOIS" && [[ "$is_private" == false ]]; then
        local netrange cidr abuse_email bgp_asn total_prefixes rpki_status
        netrange=$(echo "$whois_data" | jq -r '.netrange // "N/A"')
        cidr=$(echo "$whois_data" | jq -r '.cidr // "N/A"')
        abuse_email=$(echo "$whois_data" | jq -r '.abuse_email // "N/A"')

        bgp_asn=$(echo "$bgp_data" | jq -r '.asn // "N/A"')
        total_prefixes=$(echo "$bgp_data" | jq -r '.total_prefixes // 0')
        rpki_status=$(echo "$bgp_data" | jq -r '.rpki_status // "N/A"')

        echo
        echo -e "${BOLD}${MAGENTA}=================== WHOIS / REGISTRY DATA ===================${RESET}"
        draw_line
        table_row "NETRANGE" "$netrange"
        table_row "CIDR" "$cidr"
        table_row "ABUSE CONTACT" "$abuse_email"
        draw_line

        echo
        echo -e "${BOLD}${MAGENTA}=================== BGP ROUTING INTEL ===================${RESET}"
        draw_line
        table_row "ASN" "$bgp_asn"
        table_row "TOTAL PREFIXES" "$total_prefixes"
        table_row "RPKI STATUS" "$rpki_status"
        draw_line

        if [[ "$total_prefixes" -gt 0 ]]; then
            echo -e "${BOLD}Sample Advertised Prefixes:${RESET}"
            mapfile -t prefix_list < <(echo "$bgp_data" | jq -r '.sample_prefixes[]' 2>/dev/null || true)
            for p in "${prefix_list[@]}"; do
                table_row "PREFIX" "$p"
            done
            draw_line
        fi
    fi

    if should_run_module "DNS" && [[ "$dns_data" != "{}" ]]; then
        echo
        echo -e "${BOLD}${MAGENTA}=================== DNS ENUMERATION ===================${RESET}"
        draw_line
        mapfile -t ns_arr < <(echo "$dns_data" | jq -r '.NS[]' 2>/dev/null || true)
        mapfile -t mx_arr < <(echo "$dns_data" | jq -r '.MX[]' 2>/dev/null || true)
        mapfile -t txt_arr < <(echo "$dns_data" | jq -r '.TXT[]' 2>/dev/null || true)

        for ns in "${ns_arr[@]}"; do table_row "NS RECORD" "$ns"; done
        for mx in "${mx_arr[@]}"; do table_row "MX RECORD" "$mx"; done
        for txt in "${txt_arr[@]}"; do table_row "TXT RECORD" "$txt"; done
        draw_line
    fi

    if should_run_module "WEB" && [[ "$web_data" != "{}" ]]; then
        echo
        echo -e "${BOLD}${MAGENTA}=================== WEB RECONNAISSANCE ===================${RESET}"
        draw_line
        table_row "HTTP STATUS" "$(echo "$web_data" | jq -r '.http_status // "N/A"')"
        table_row "SERVER HEADER" "$(echo "$web_data" | jq -r '.server // "N/A"')"
        table_row "X-POWERED-BY" "$(echo "$web_data" | jq -r '.x_powered_by // "N/A"')"
        table_row "PAGE TITLE" "$(echo "$web_data" | jq -r '.page_title // "N/A"')"
        draw_line
    fi

    if should_run_module "SUBDOMAIN" && [[ "$subdomains_data" != "{}" ]]; then
        echo
        echo -e "${BOLD}${MAGENTA}=================== SUBDOMAIN DISCOVERY (ALIVE VS DEAD) ===================${RESET}"
        echo -e "${CYAN}+----------+-------------------------------------+-------------------+${RESET}"
        printf "${CYAN}|${RESET} %-8s ${CYAN}|${RESET} %-35s ${CYAN}|${RESET} %-17s ${CYAN}|${RESET}\n" "STATUS" "SUBDOMAIN" "RESOLVED IP"
        echo -e "${CYAN}+----------+-------------------------------------+-------------------+${RESET}"

        mapfile -t alive_list < <(echo "$subdomains_data" | jq -r '.alive_subdomains[]? // empty' 2>/dev/null || true)
        mapfile -t dead_list < <(echo "$subdomains_data" | jq -r '.dead_subdomains[]? // empty' 2>/dev/null || true)

        for entry in "${alive_list[@]}"; do
            if [[ -n "$entry" ]]; then
                IFS='|' read -r sub ip_addr <<< "$entry"
                printf "${CYAN}|${RESET} ${GREEN}%-8s${RESET} ${CYAN}|${RESET} %-35s ${CYAN}|${RESET} %-17s ${CYAN}|${RESET}\n" "ALIVE" "${sub:0:35}" "${ip_addr:0:17}"
            fi
        done

        for entry in "${dead_list[@]}"; do
            if [[ -n "$entry" ]]; then
                IFS='|' read -r sub ip_addr <<< "$entry"
                printf "${CYAN}|${RESET} ${RED}%-8s${RESET} ${CYAN}|${RESET} %-35s ${CYAN}|${RESET} %-17s ${CYAN}|${RESET}\n" "DEAD" "${sub:0:35}" "${ip_addr:0:17}"
            fi
        done
        echo -e "${CYAN}+----------+-------------------------------------+-------------------+${RESET}"
    fi

    echo
}

main "$@"
