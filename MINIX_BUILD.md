# Building Network Ambulance on MINIX

## Overview

MINIX 3.x support is **limited to command-line tools** (D CLI and Ada TUI) due to:
- **No Tauri GUI**: Rust std support incomplete, no WebView2/WebKitGTK
- **Limited modern toolchain**: C++17/20 features unavailable
- **No ReScript/Deno**: V8 engine not available

**Supported on MINIX:**
- ✅ D CLI (`network-ambulance-d`)
- ✅ Ada TUI (`network_ambulance_tui`)
- ✅ Shell scripts (legacy Bash implementation)

**NOT Supported on MINIX:**
- ❌ Tauri + ReScript GUI
- ❌ Mobile builds
- ❌ Modern web technologies

## Prerequisites

### MINIX 3.4.0+ Required

```bash
# Check MINIX version
uname -a
# Should show: MINIX 3.4.0 or later
```

### Install pkgin Package Manager

```bash
# Update pkgin
pkgin update

# Install build tools
pkgin install gmake gcc binutils
```

## Building D CLI on MINIX

### Install DMD (D Compiler)

**Option 1: From Binary (Recommended)**
```bash
# Download DMD for NetBSD (MINIX uses NetBSD pkgsrc)
cd /tmp
curl -LO https://downloads.dlang.org/releases/2.x/2.110.0/dmd.2.110.0.netbsd-x86.tar.xz
tar xf dmd.2.110.0.netbsd-x86.tar.xz
sudo cp -r dmd2/* /usr/local/

# Verify
dmd --version
```

**Option 2: From pkgsrc**
```bash
# If available in pkgsrc
pkgin search dmd
pkgin install dmd dub
```

### Build Network Ambulance D CLI

```bash
cd ~/network-ambulance

# Build release binary
dub build --build=release

# Test
./bin/network-ambulance-d version
./bin/network-ambulance-d diagnose
```

### MINIX-Specific Notes

**Network Commands:**
- MINIX uses older `ifconfig` instead of `ip` (Linux)
- Some diagnostics may require root: `su` then run commands
- `dig` may not be available - use `nslookup` fallback

**Expected Limitations:**
- No systemd (uses rc scripts)
- Limited wireless support
- IPv6 may be incomplete
- Some repair operations unavailable

## Building Ada TUI on MINIX

### Install GNAT (Ada Compiler)

```bash
# GNAT from pkgsrc (if available)
pkgin search gnat
pkgin install gcc-ada gprbuild

# Or build from source (advanced)
# Download GNAT from https://gcc.gnu.org/
```

### Build Network Ambulance Ada TUI

```bash
cd ~/network-ambulance

# Build Ada TUI
gprbuild -P network_ambulance_tui.gpr -XBUILD_MODE=release

# Test
./bin/network_ambulance_tui
```

### Terminal Requirements

The Ada TUI uses ANSI escape codes and requires:
- VT100-compatible terminal
- UTF-8 support (optional, uses ASCII fallback)

On MINIX console:
```bash
# Set TERM if needed
export TERM=vt100

# Run TUI
./bin/network_ambulance_tui
```

## Platform Abstraction for MINIX

The D platform code needs MINIX-specific implementation:

### Create `src/d/platform/minix.d`:

```d
// MINIX platform implementation
module platform.minix;

import platform.iface;
import platform.types;

class MinixPlatform : NetworkPlatform {
    // Uses ifconfig instead of ip command
    override InterfaceInfo[] getInterfaces() @trusted {
        import std.process : execute;
        auto result = execute(["ifconfig", "-a"]);
        // Parse ifconfig output (BSD-style)
        // ...
    }

    // MINIX-specific implementations
    // ...
}

NetworkPlatform getPlatform() @safe {
    return new MinixPlatform();
}
```

### Modify `src/d/platform/package.d`:

```d
version(MINIX) {
    public import platform.minix;
} else version(linux) {
    public import platform.linux;
} else // ...
```

### Build with MINIX Support:

```d
dub build --build=release -d MINIX
```

## Shell Script Fallback

If D/Ada compilation fails, use the legacy Bash implementation:

```bash
# The original Bash version works on MINIX
cd ~/network-ambulance
chmod +x network-ambulance.sh

# Run diagnostics
./network-ambulance.sh diagnose

# Run repairs (requires root)
su
./network-ambulance.sh repair
```

## Cross-Compilation to MINIX

### From Linux to MINIX:

```bash
# Install MINIX cross-compiler
# (Not commonly available, build from source)

# Cross-compile D
dmd -m32 -od=obj-minix -of=bin/network-ambulance-d-minix src/d/**/*.d

# Transfer to MINIX
scp bin/network-ambulance-d-minix user@minix-host:/usr/local/bin/
```

## Troubleshooting

### Error: `dmd: command not found`
- Install DMD from NetBSD packages or binary download
- Add to PATH: `export PATH=$PATH:/usr/local/dmd2/bin`

### Error: `ip: command not found`
- Expected on MINIX - D code should detect and use `ifconfig`
- Implement MINIX platform abstraction (see above)

### Error: `gprbuild: command not found`
- Install GNAT/gprbuild from pkgsrc
- Or skip Ada TUI and use D CLI only

### Network commands fail:
- Run with root: `su` or `sudo` (if configured)
- Check if interface names differ (e.g., `re0` instead of `eth0`)

### Terminal rendering issues:
```bash
# Set basic terminal
export TERM=vt100

# Disable UTF-8 if garbled
export LC_ALL=C
```

## Performance Considerations

MINIX is designed for reliability over performance:
- D CLI: Fast, lightweight (~2-5MB binary)
- Ada TUI: Slightly larger (~300KB), but still efficient
- Expect slower execution than Linux/BSD
- Network operations may take longer

## Feature Matrix: MINIX vs Other Platforms

| Feature | MINIX | Linux | macOS | Windows |
|---------|-------|-------|-------|---------|
| D CLI | ✅ | ✅ | ✅ | ⚠️ Limited |
| Ada TUI | ✅ | ✅ | ✅ | ⚠️ Limited |
| Tauri GUI | ❌ | ✅ | ✅ | ✅ |
| Mobile GUI | ❌ | ❌ | ✅ iOS | ✅ Android |
| DNS Diagnostics | ✅ | ✅ | ✅ | ✅ |
| Routing Diagnostics | ⚠️ Basic | ✅ Full | ✅ Full | ⚠️ Limited |
| Interface Diagnostics | ✅ | ✅ | ✅ | ⚠️ Limited |
| Automated Repairs | ⚠️ Limited | ✅ Full | ⚠️ Limited | ❌ |
| JSON Output | ✅ | ✅ | ✅ | ✅ |
| SPARK Verification | ✅ | ✅ | ✅ | ✅ |

Legend:
- ✅ Fully supported
- ⚠️ Partially supported / limited
- ❌ Not supported

## Recommended Configuration for MINIX

Use the **D CLI** for MINIX deployments:

```bash
# Install D CLI
dub build --build=release

# Create alias for convenience
echo 'alias netamb="/usr/local/bin/network-ambulance-d"' >> ~/.profile

# Run diagnostics
netamb diagnose

# Get JSON output for scripting
netamb diagnose --json | json_pp
```

For interactive use, the **Ada TUI** provides a better experience than raw CLI.

## Future MINIX Support

Potential improvements:
- [ ] Complete MINIX platform abstraction in D
- [ ] Port more repair operations to MINIX
- [ ] MINIX-specific test suite
- [ ] pkgsrc package for easy installation
- [ ] MINIX 4.x support when available

## References

- MINIX 3 Official: https://www.minix3.org/
- pkgin Documentation: https://pkgin.net/
- D Language on BSD: https://dlang.org/download.html#bsd
- GNAT on NetBSD: https://www.netbsd.org/docs/pkgsrc/

## Support

For MINIX-specific issues:
- Check if feature exists on target platform
- Use D CLI instead of GUI for maximum compatibility
- Report MINIX bugs with `uname -a` output
- Test on MINIX 3.4.0+ (earlier versions untested)
