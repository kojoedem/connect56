# CONNECT56

CONNECT56 is a Bash-based network diagnostic tool that checks internet connectivity and retrieves IP, WHOIS, and BGP routing information.

This project is part of my learning journey into Bash scripting and network automation.

---

## 🚀 Features

* Checks internet connectivity using ICMP (ping)
* Displays your public IP address
* Retrieves IP details:

  * Hostname
  * ASN (Autonomous System Number)
  * Organization
  * City and Country
* Performs WHOIS lookup:

  * NetRange / inetnum
  * CIDR
  * Abuse contact details (if available)
* Extracts BGP routing information from RADB:

  * Advertised prefixes
  * RPKI status
  * Sample routes with descriptions
* Outputs results in a clean table format

---

## ⚡ Quick Setup (Recommended)

Clone the project and install dependencies in one flow:

```bash
git clone https://github.com/kojoedem/connect56.git
cd connect56
chmod +x *.sh
./setup.sh
./connect56.sh
```

---

## 🛠️ Manual Installation (Alternative)

If you prefer installing dependencies manually:

```bash
sudo apt update
sudo apt install curl jq whois
```

---

## 📦 Setup Script

The project includes a simple setup script:

```bash
./setup.sh
```

This will:

* Update package lists
* Install required tools (`curl`, `jq`, `whois`)

---

## ▶️ Usage

### Run with IP address

```bash
./connect56.sh 8.8.8.8
```

---

### Run without IP address (interactive mode)

```bash
./connect56.sh
```

You will be prompted to enter an IP address.

---

## 🧠 How It Works

1. Displays a welcome banner
2. Checks internet connectivity using `ping`
3. Retrieves your public IP using `curl`
4. Accepts an IP address (argument or user input)
5. Fetches IP details from `ipinfo.io`
6. Performs WHOIS lookup for registry data
7. Queries RADB (`whois.radb.net`) for BGP routing information
8. Formats all output into readable tables

---

## 📁 Project Structure

```
connect56.sh   # Main Bash script
setup.sh       # Dependency installer
README.md      # Documentation
```

---

## 📊 Example Output

```
INTERNET AVAILABLE

Your Public IP address is: 41.x.x.x

----------------------------------------------------------
| FIELD      | VALUE                                     |
----------------------------------------------------------
| HOSTNAME   | N/A                                       |
| ASN        | AS37030                                   |
| ORG        | Airtel Ghana Limited                      |
| CITY       | Accra                                     |
| COUNTRY    | GH                                        |
----------------------------------------------------------

| NETRANGE   | 41.x.x.0 - 41.x.x.255                     |
| CIDR       | 41.x.x.0/24                               |
----------------------------------------------------------

| ASN        | AS37030                                   |
| TOTAL PREFIX | 92                                      |
| RPKI STATUS | not_found                                |
----------------------------------------------------------
```

---

## 🎯 Learning Objectives

This project focuses on:

* Bash scripting fundamentals
* Working with command-line tools (`grep`, `awk`, `cut`)
* Using APIs with `curl`
* Parsing JSON with `jq`
* Understanding WHOIS and BGP data

---

## 🔧 Future Improvements

* Input validation for IP addresses
* Error handling for API failures
* Support for multiple IP lookups
* Add command-line flags (e.g., help option)
* Improve parsing reliability across registries

---

## ⚠️ Notes

* Tested on Ubuntu/Debian-based systems
* Other distributions may require different package managers (`dnf`, `yum`, `brew`)

---

## 👨‍💻 Author

**Edem Robin**
Network Engineer | Learning Automation & Scripting

---

## 📜 License

This project is open-source and available under the MIT License.
