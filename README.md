# CONNECT56 v2.0 - Production Cyber Security & Network Intelligence CLI Tool

`CONNECT56` is an advanced Bash-based cyber security reconnaissance and network intelligence CLI tool designed for security analysts, network engineers, and system administrators.

It performs automated target inspection against **IPv4/IPv6 addresses** and **domain names**, delivering comprehensive threat intelligence, WHOIS/RDAP records, BGP routing data, DNS enumeration, web technology reconnaissance, and health-monitored subdomain discovery.

---

## ⚡ Features

* **Target Auto-Resolution**: Resolves domain names to IP addresses or retrieves PTR (Reverse DNS) records for IP targets.
* **Interactive Intelligence Selector**: Interactive prompt allows selecting full scans or targeted modules (`WHOIS`, `DNS`, `WEB`, `SUBDOMAIN`).
* **WHOIS & RDAP Lookup**: Extracts registry ownership, netranges, CIDR blocks, and abuse contacts with automated API fallback.
* **BGP Routing & RPKI Validation**: Queries RIPE Stat REST API and RADB WHOIS for advertised BGP prefixes, total prefix counts, and RPKI validity.
* **DNS Enumeration**: Queries `A`, `AAAA`, `NS`, `MX`, and `TXT` (SPF/verification) records using `dig`, `host`, or `nslookup`.
* **Web Technology Reconnaissance**: Fingerprints HTTP status codes, Server headers, `X-Powered-By` technologies, redirects, and HTML page titles via `curl`.
* **Subdomain Discovery (Alive vs Dead)**: Queries Certificate Transparency logs (`crt.sh`) and candidate lists, probing DNS resolution to classify subdomains into **ALIVE** or **DEAD** in a clean table format.
* **Private/Bogon IP Protection**: Detects RFC 1918, RFC 4193, loopback, and CGNAT IP addresses automatically.
* **JSON Pipeline Integration**: Includes `--json` flag to output structured JSON suitable for SIEMs, log aggregators, and script automation.
* **ANSI Colorized Output**: Dynamic terminal coloring with automatic pipe detection and `--no-color` support.
* **System Man Page Integration**: Native Linux manual page (`man connect56`).

---

## 🚀 Quick Installation

Clone the repository, run the setup script, and start scanning:

```bash
git clone https://github.com/kojoedem/connect56.git
cd connect56
chmod +x *.sh
./setup.sh
```

Running `./setup.sh` automatically installs required system dependencies (`curl`, `jq`, `whois`, `bind-utils`/`dnsutils`) across major Linux distributions (`apt`, `dnf`, `yum`, `pacman`, `brew`) and installs the manual page so you can run `man connect56`.

---

## 📖 Usage & Syntax

```bash
./connect56.sh [OPTIONS] [IP_ADDRESS | DOMAIN]
```

### Options & Flags

| Flag | Long Flag | Description |
| :--- | :--- | :--- |
| `-j` | `--json` | Output structured JSON data for security pipelines |
| `-c` | `--no-color` | Disable ANSI colorized terminal output |
| `-q` | `--quiet` | Suppress banners and non-essential logs |
| `-m` | `--modules` | Specify module subset: `all`, `whois`, `dns`, `web`, `subdomain` |
| `-v` | `--version` | Display version information |
| `-h` | `--help` | Display command usage and examples |
|`-l` | `--lan-scan`|Scan the local network for devices and open ports |

---

## 💡 Examples

### Interactive Profile Selection
```bash
./connect56.sh
```
Prompts the user to enter a target domain/IP and choose which intelligence modules to run.

### Full Target Reconnaissance
```bash
./connect56.sh 8.8.8.8
./connect56.sh example.com
```

### JSON Pipeline Output (SIEM / Automation)
```bash
./connect56.sh google.com --json | jq .
```

### Specific Module Execution
```bash
./connect56.sh example.com --modules dns,subdomain
```

### View System Manual Page
```bash
man connect56
```

---

## 📊 Sample Output

```
=================== TARGET SUMMARY: 172.217.214.100 ===================
+-----------------+---------------------------------------------------------+
| TARGET          | google.com                                              |
| RESOLVED IP     | 172.217.214.100                                         |
| PTR (REVERSE DNS) | jr-in-f100.1e100.net                                    |
| IS PRIVATE/BOGON | false                                                   |
+-----------------+---------------------------------------------------------+

=================== SUBDOMAIN DISCOVERY (ALIVE VS DEAD) ===================
+----------+-------------------------------------+-------------------+
| STATUS   | SUBDOMAIN                           | RESOLVED IP       |
+----------+-------------------------------------+-------------------+
| ALIVE    | accounts.google.com                 | 192.178.212.84    |
| ALIVE    | adwords.google.com                  | 74.125.202.100    |
| ALIVE    | mail.google.com                     | 142.251.183.17    |
| DEAD     | secure.google.com                   | UNRESOLVED        |
| DEAD     | vpn.google.com                      | UNRESOLVED        |
+----------+-------------------------------------+-------------------+
```

---

## 📁 Repository Structure

```
connect56.sh   # Main CLI executable
setup.sh       # Multi-distro package & man page installer
connect56.1    # Troff format man page for 'man connect56'
README.md      # Comprehensive documentation
```

---

## 👨‍💻 Author

**Edem Robin**
Network Engineer | Cyber Security & Network Automation

---

## 📜 License

This project is licensed under the MIT License - see the `LICENSE` file for details.

# LAN Scanner

A simple Bash-based LAN scanning tool that uses **Nmap** to discover devices on a local network and identify their open ports.

The tool can automatically detect the local subnet or accept a specific subnet and port range as arguments.

## Features

* 🔍 Automatic local subnet detection
* 🖥️ Discover live hosts on the LAN
* 🌐 Display hostnames and IP addresses
* 🔗 Identify MAC addresses
* 🚪 Scan for open ports
* 📄 Save scan results to a timestamped report
* ⚡ Supports direct command-line usage
* 🔧 Can be integrated with `connect56.sh`

---

## Requirements

### Nmap

Install Nmap if it is not already installed:

```bash
sudo apt install nmap
```

### Sudo / Root Access

Sudo access is recommended for accurate ARP-based host discovery.

---

## Usage

### Direct Usage

Make sure the script is executable:

```bash
chmod +x lan_scan.sh
```

You can then run it directly.

### Scan the automatically detected subnet

```bash
sudo ./lan_scan.sh
```

This automatically detects the subnet associated with the default route and scans ports **1-1000**.

### Scan a specific subnet

```bash
sudo ./lan_scan.sh 192.168.1.0/24
```

### Scan a specific subnet and port range

```bash
sudo ./lan_scan.sh 192.168.1.0/24 1-65535
```

You can also specify common ports:

```bash
sudo ./lan_scan.sh 192.168.1.0/24 22,80,443
```

---

## Arguments

Both arguments are optional and positional.

| Argument | Description                                  | Default                |
| -------- | -------------------------------------------- | ---------------------- |
| `1`      | Subnet in CIDR format, e.g. `192.168.1.0/24` | Automatically detected |
| `2`      | Port range, e.g. `1-1024` or `22,80,443`     | `1-1000`               |

### Examples

```bash
sudo ./lan_scan.sh
```

```bash
sudo ./lan_scan.sh 10.0.0.0/24
```

```bash
sudo ./lan_scan.sh 10.0.0.0/24 1-1024
```

```bash
sudo ./lan_scan.sh 10.0.0.0/24 22,80,443
```

---

## Scan Results

The scanner displays discovered information directly in the terminal, including:

* IP address
* Hostname
* MAC address
* Open ports

A full report is also saved automatically.

Reports are stored in:

```text
./lan_scan_results/
```

Example:

```text
lan_scan_results/
└── scan_2026-09-26_114500.txt
```

This makes it easy to keep a history of previous LAN scans.

---

## Using LAN Scanner with Connect56

If `lan_scan.sh` is located in the same directory as `connect56.sh`, you can launch it through the **Connect56** menu.

Run:

```bash
./connect56.sh
```

Then select:

```text
[8] Local Area Network Scan
```

### Direct Connect56 Usage

You can also bypass the menu and launch the scanner directly.

```bash
./connect56.sh -l
```

Or specify the subnet and port range:

```bash
./connect56.sh --lan-scan 192.168.1.0/24 1-1024
```

Any arguments provided after `-l` or `--lan-scan` are passed directly to `lan_scan.sh`.

For example:

```bash
./connect56.sh --lan-scan 10.0.0.0/24 22,80,443
```

---

## Example Workflow

A typical LAN scan can be performed with:

```bash
sudo ./lan_scan.sh 192.168.1.0/24 1-1000
```

The tool discovers active devices and checks them for open ports.

Example output:

```text
IP Address       Hostname          MAC Address          Open Ports
---------------------------------------------------------------------------
192.168.1.1      router.local      AA:BB:CC:DD:EE:FF    22,80
192.168.1.10     desktop.local     11:22:33:44:55:66    22,445
192.168.1.20     printer.local     77:88:99:AA:BB:CC    80,443
```

The same information is saved to the generated report.

---

## Permissions

Running the scanner without `sudo` may result in incomplete host discovery or inaccurate results.

For the most reliable results, use:

```bash
sudo ./lan_scan.sh
```

---

## Legal & Ethical Use

Only scan networks and devices that you **own or have explicit permission to test**.

Network scanning can generate traffic and may trigger security alerts on monitored networks.

Use this tool responsibly and only within authorized environments.

---

## Project

**Connect56 — IP & Network Intelligence Toolkit**

Built with Bash and Nmap.

Developed by **Edem Robin**.
