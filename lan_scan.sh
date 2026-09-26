#!/usr/bin/env bash
#
# lan_scan.sh — Discover devices on the local network and report their open ports.
#
# Usage:
#   ./lan_scan.sh [subnet] [port-range]
#
# Examples:
#   ./lan_scan.sh                        # auto-detect subnet, scan top 1000 ports
#   ./lan_scan.sh 192.168.1.0/24         # scan a specific subnet
#   ./lan_scan.sh 192.168.1.0/24 1-1024  # scan a specific subnet and port range
#
# Requires: nmap (sudo/root recommended for accurate host discovery and OS/service detection)

set -euo pipefail

# ---- Config ------------------------------------------------------------

PORT_RANGE="${2:-1-1000}"
OUT_DIR="./lan_scan_results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="${OUT_DIR}/scan_${TIMESTAMP}.txt"

# ---- Helpers -------------------------------------------------------------

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: '$1' is required but not installed." >&2
        echo "Install it with: sudo apt install $1  (Debian/Ubuntu)" >&2
        echo "                 sudo yum install $1  (RHEL/CentOS)" >&2
        exit 1
    fi
}

detect_subnet() {
    # Try to auto-detect the local subnet from the default route interface.
    local iface cidr
    iface="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')"
    if [ -z "$iface" ]; then
        echo ""
        return
    fi
    cidr="$(ip -o -f inet addr show "$iface" 2>/dev/null | awk '{print $4; exit}')"
    echo "$cidr"
}

# ---- Pre-flight checks -----------------------------------------------------

need_cmd nmap

if [ "$EUID" -ne 0 ]; then
    echo "Note: not running as root — host discovery and port scan accuracy may be reduced."
    echo "      Re-run with 'sudo $0 $*' for best results."
    echo
fi

SUBNET="${1:-$(detect_subnet)}"

if [ -z "$SUBNET" ]; then
    echo "Error: could not auto-detect subnet. Please supply one, e.g.:" >&2
    echo "  $0 192.168.1.0/24" >&2
    exit 1
fi

mkdir -p "$OUT_DIR"

echo "=========================================================="
echo " LAN Scan"
echo "   Subnet:      $SUBNET"
echo "   Port range:  $PORT_RANGE"
echo "   Results log: $OUT_FILE"
echo "=========================================================="
echo

# ---- Step 1: Host discovery ------------------------------------------------

echo "[1/2] Discovering live hosts on $SUBNET ..."
# -sn : ping scan only (no port scan yet), -PR: ARP scan for local subnets
mapfile -t HOSTS < <(nmap -sn "$SUBNET" -oG - 2>/dev/null | awk '/Up$/{print $2}')

if [ "${#HOSTS[@]}" -eq 0 ]; then
    echo "No live hosts found on $SUBNET. Exiting."
    exit 0
fi

echo "Found ${#HOSTS[@]} live host(s)."
echo

{
    echo "LAN Scan Report — $(date)"
    echo "Subnet: $SUBNET"
    echo "Port range: $PORT_RANGE"
    echo "----------------------------------------------------------"
} > "$OUT_FILE"

# ---- Step 2: Port scan per host --------------------------------------------

echo "[2/2] Scanning ports on each host (this may take a while) ..."
echo

for ip in "${HOSTS[@]}"; do
    echo "------------------------------------------------------------"
    echo " Host: $ip"

    # -sV: service/version detection, -T4: faster timing, --open: only show open ports
    RESULT="$(nmap -sV -T4 --open -p "$PORT_RANGE" "$ip" 2>/dev/null)"

    HOSTNAME="$(echo "$RESULT" | awk -F'for ' '/Nmap scan report/{print $2}')"
    MAC_LINE="$(echo "$RESULT" | grep -i "MAC Address" || true)"
    OPEN_PORTS="$(echo "$RESULT" | awk '/^[0-9]+\/(tcp|udp)/{print}')"

    [ -n "$HOSTNAME" ] && echo " Name: $HOSTNAME"
    [ -n "$MAC_LINE" ] && echo " $MAC_LINE"

    if [ -n "$OPEN_PORTS" ]; then
        echo " Open ports:"
        echo "$OPEN_PORTS" | sed 's/^/   /'
    else
        echo " Open ports: none found in range $PORT_RANGE"
    fi
    echo

    {
        echo "Host: $ip"
        [ -n "$HOSTNAME" ] && echo "Name: $HOSTNAME"
        [ -n "$MAC_LINE" ] && echo "$MAC_LINE"
        if [ -n "$OPEN_PORTS" ]; then
            echo "Open ports:"
            echo "$OPEN_PORTS"
        else
            echo "Open ports: none found in range $PORT_RANGE"
        fi
        echo "----------------------------------------------------------"
    } >> "$OUT_FILE"
done

echo "=========================================================="
echo " Scan complete. Full report saved to: $OUT_FILE"
echo "=========================================================="
