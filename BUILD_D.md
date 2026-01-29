# Building Network Ambulance D Implementation

## Prerequisites

### Install D compiler (DMD or LDC)

**Fedora:**
```bash
sudo dnf install dmd dub
```

**Ubuntu/Debian:**
```bash
curl -fsS https://dlang.org/install.sh | bash -s dmd
source ~/dlang/dmd-*/activate
```

**Arch:**
```bash
sudo pacman -S dlang dub
```

**Or use official installer:**
```bash
curl https://dlang.org/install.sh | bash -s
source ~/dlang/dmd-*/activate
```

## Building

### Debug build (default):
```bash
dub build
```

### Release build (optimized):
```bash
dub build --build=release
```

### Safe mode build (extra safety checks):
```bash
dub build --build=safe
```

## Running

```bash
# After building, binary is in bin/
./bin/network-ambulance-d diagnose

# Or run directly with dub (slower, recompiles):
dub run -- diagnose

# Quick status:
./bin/network-ambulance-d status

# Verbose diagnostics:
./bin/network-ambulance-d diagnose --verbose

# Version:
./bin/network-ambulance-d version
```

## Testing

```bash
# Run built-in tests:
dub test

# Run with verbose output:
dub run -- diagnose -v
```

## Installation

```bash
# Install to system:
dub build --build=release
sudo install -m 755 bin/network-ambulance-d /usr/local/bin/
```

## Development

```bash
# Clean build artifacts:
dub clean

# Show dependencies:
dub describe

# Lint code:
dub lint

# Generate documentation:
dub build --build=docs
```

## Platform-Specific Notes

### Linux
- Full feature set available
- Requires `ip`, `ping`, `dig` commands
- Some operations require root/sudo

### macOS
- Basic diagnostics available
- Requires `networksetup`, `route`, `ping`, `dig`
- Limited repair capabilities

### BSD
- Similar to Linux
- Uses BSD-specific commands where needed

### Windows
- Limited support
- Requires WSL2 for full functionality

## Troubleshooting

**Error: `dub: command not found`**
- Install D compiler and Dub package manager

**Error: `ip: command not found`**
- Install iproute2: `sudo dnf install iproute` or `sudo apt install iproute2`

**Permission denied errors:**
- Run with sudo for operations that modify network configuration:
  ```bash
  sudo ./bin/network-ambulance-d diagnose
  ```

**Import errors:**
- Make sure you're in the network-ambulance directory
- Check that all source files are present in `src/d/`
