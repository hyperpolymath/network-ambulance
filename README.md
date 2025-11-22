# Complete Linux Internet Repair Tool

A comprehensive, automated toolkit for diagnosing and repairing internet connectivity issues on Linux systems.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux-lightgrey.svg)](https://www.linux.org/)
[![RSR Compliance](https://img.shields.io/badge/RSR-Silver-silver.svg)](RSR-COMPLIANCE.md)
[![TPCF](https://img.shields.io/badge/TPCF-Perimeter%203-blue.svg)](TPCF.md)

## Features

- **Comprehensive Diagnostics**: Automatically detect network issues
  - DNS configuration and resolution
  - Network interface status
  - Routing table problems
  - Internet connectivity
  - Firewall configuration
  - NetworkManager issues

- **Automated Repairs**: Fix common problems automatically
  - DNS server configuration
  - Network interface management
  - Routing table repair
  - DHCP lease renewal
  - NetworkManager reconnection

- **Multiple Modes**:
  - CLI mode for quick diagnostics
  - Interactive guided mode for beginners
  - Auto-repair mode for hands-off operation
  - Dry-run mode to preview changes

- **Safety Features**:
  - Automatic backups before modifications
  - Dry-run mode
  - Detailed logging
  - Root privilege checking

- **Distribution Support**:
  - Ubuntu (20.04, 22.04, 24.04)
  - Debian (11, 12)
  - Fedora (38, 39, 40)
  - Arch Linux
  - And more...

## Standards Compliance

This project follows the **RSR (Rhodium Standard Repository) Framework** at **Silver Level**:

- ✅ Complete documentation (README, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, MAINTAINERS)
- ✅ TPCF (Tri-Perimeter Contribution Framework) for graduated trust
- ✅ .well-known directory (security.txt RFC 9116, ai.txt, humans.txt)
- ✅ CI/CD with automated testing
- ✅ Comprehensive test suite
- ✅ Build automation (justfile)
- ✅ Security-first design with backups and dry-run
- ✅ Accessibility features (color detection, screen reader compatible)
- ✅ i18n/l10n ready (planning for v1.2+)

See [RSR-COMPLIANCE.md](RSR-COMPLIANCE.md) for full compliance details.

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/complete-linux-internet-repair.git
cd complete-linux-internet-repair

# Install (requires root)
sudo ./install.sh
```

### Basic Usage

```bash
# Run diagnostics (no root required)
network-repair diagnose

# Run diagnostics and auto-repair (requires root)
sudo network-repair --auto-repair diagnose

# Interactive guided mode (requires root)
sudo network-repair interactive

# Repair specific issues
sudo network-repair repair-dns
sudo network-repair repair-network
sudo network-repair repair-routing
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `diagnose` | Run all diagnostics (default) |
| `diagnose-dns` | Check DNS configuration only |
| `diagnose-network` | Check network interfaces only |
| `diagnose-routing` | Check routing configuration only |
| `repair` | Run all repairs |
| `repair-dns` | Repair DNS issues only |
| `repair-network` | Repair network interfaces only |
| `repair-routing` | Repair routing issues only |
| `interactive` | Launch interactive guided mode |

### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Show version information |
| `-V, --verbose` | Enable verbose output |
| `-q, --quiet` | Quiet mode (errors only) |
| `-i, --interactive` | Run in interactive mode |
| `-a, --auto-repair` | Automatically repair found issues |
| `-d, --dry-run` | Show what would be done without doing it |
| `--no-color` | Disable colored output |
| `--log-file FILE` | Write logs to FILE |

### Examples

#### Diagnose Network Issues

```bash
# Quick diagnostics
network-repair diagnose

# Verbose diagnostics
network-repair --verbose diagnose

# Save diagnostics to log file
network-repair --log-file /tmp/network-diag.log diagnose
```

#### Repair Network Issues

```bash
# Auto-repair all issues
sudo network-repair repair

# Dry-run (preview changes)
sudo network-repair --dry-run repair

# Repair DNS only
sudo network-repair repair-dns

# Interactive repair with prompts
sudo network-repair --interactive repair
```

#### Interactive Mode

```bash
# Launch interactive guided mode
sudo network-repair interactive
```

The interactive mode provides a menu-driven interface for:
- Running diagnostics
- Performing repairs
- Viewing backups
- Getting help

## How It Works

### Diagnostic Process

1. **Interface Check**: Verifies network interfaces are up and configured
2. **Routing Check**: Validates routing table and gateway connectivity
3. **DNS Check**: Tests DNS configuration and resolution
4. **Connectivity Check**: Tests actual internet connectivity
5. **Firewall Check**: Examines firewall rules for blocking issues
6. **NetworkManager Check**: Verifies NetworkManager status

### Repair Process

1. **Backup**: Creates backups of configuration files
2. **Interface Repair**: Brings up interfaces and renews DHCP
3. **Routing Repair**: Fixes routing table and default gateway
4. **DNS Repair**: Configures working DNS servers
5. **NetworkManager Repair**: Restarts and reconfigures NetworkManager
6. **Verification**: Tests internet connectivity

## Architecture

```
complete-linux-internet-repair/
├── src/
│   ├── main.sh                 # Main entry point
│   ├── diagnostics/            # Diagnostic modules
│   │   ├── dns.sh
│   │   ├── interfaces.sh
│   │   ├── routing.sh
│   │   ├── connectivity.sh
│   │   ├── firewall.sh
│   │   └── networkmanager.sh
│   ├── repairs/                # Repair modules
│   │   ├── dns.sh
│   │   ├── interfaces.sh
│   │   ├── routing.sh
│   │   └── networkmanager.sh
│   └── utils/                  # Utility functions
│       ├── logging.sh
│       ├── colors.sh
│       ├── privileges.sh
│       ├── backup.sh
│       └── system.sh
├── tests/                      # Test suite
├── config/                     # Configuration files
├── docs/                       # Documentation
└── network-repair              # Main wrapper script
```

## Requirements

### Required

- Bash 4.0+
- iproute2 (`ip` command)
- iputils (`ping` command)
- systemd (for most distributions)

### Optional

- NetworkManager (`nmcli` command) - for NetworkManager management
- dnsutils/bind-utils (`dig` command) - for DNS testing
- curl or wget - for HTTP connectivity tests
- netcat (`nc` command) - for port connectivity tests

## Configuration

Default configuration is located at `/opt/network-repair/config/defaults.conf` (after installation).

You can override settings using environment variables:

```bash
# Enable verbose logging
VERBOSE=true network-repair diagnose

# Use custom DNS servers
DEFAULT_DNS_SERVERS="8.8.8.8 1.1.1.1" sudo network-repair repair-dns

# Change backup directory
BACKUP_DIR=/tmp/backups sudo network-repair repair
```

## Troubleshooting

### Permission Errors

Most repair operations require root privileges:

```bash
sudo network-repair repair
```

### Network Still Not Working

If the tool doesn't fix your issue:

1. Check the verbose output: `network-repair --verbose diagnose`
2. Review the log file: `network-repair --log-file /tmp/diag.log diagnose`
3. Try individual repair modules
4. Check for hardware issues (cable, wireless signal)
5. Verify with your network administrator

### Backups

All modified files are backed up to `~/.network-repair-backups/`:

```bash
# List backups
ls -l ~/.network-repair-backups/

# View a specific backup
cat ~/.network-repair-backups/resolv.conf.20250122_143052
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/complete-linux-internet-repair/issues)
- **Documentation**: [docs/](docs/)
- **Examples**: [examples/](examples/)

## Acknowledgments

- Inspired by common Linux networking troubleshooting procedures
- Built with bash and standard Linux networking tools
- Tested on multiple distributions and network configurations

## Roadmap

- [ ] Additional diagnostic checks (proxy, VPN)
- [ ] Support for more network managers
- [ ] Web-based dashboard
- [ ] Automated testing framework
- [ ] Package repository releases (apt, yum, AUR)
- [ ] IPv6 support improvements
- [ ] Wireless-specific diagnostics

## Authors

- **Your Name** - *Initial work*

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.
