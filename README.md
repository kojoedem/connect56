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
