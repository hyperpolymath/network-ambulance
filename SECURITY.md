# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Considerations

### This Tool Requires Root Privileges

The Complete Linux Internet Repair Tool performs network configuration changes that require root/sudo access. This is by design and necessary for:

- Modifying `/etc/resolv.conf` and other network configuration files
- Bringing network interfaces up/down
- Modifying routing tables
- Restarting system services (NetworkManager, systemd-resolved, etc.)
- Running privileged network commands (`ip`, `iptables`, etc.)

### Security Measures Implemented

1. **Privilege Checking**
   - Explicit privilege checks before operations
   - Clear user notification when sudo is required
   - Sudo keep-alive only for duration of operations
   - No unnecessary privilege escalation

2. **Input Sanitization**
   - All user inputs are sanitized to prevent command injection
   - Interface names validated against system interfaces
   - File paths validated before access
   - No arbitrary command execution from user input

3. **File Safety**
   - Automatic backups before modifying configuration files
   - Backups stored in user's home directory (`~/.network-repair-backups/`)
   - File permission preservation
   - Atomic file operations where possible

4. **Code Safety**
   - Bash strict mode (`set -euo pipefail`) where appropriate
   - Proper error handling and validation
   - No use of `eval` or dangerous constructs
   - Shell script best practices followed

5. **Transparency**
   - Detailed logging of all operations
   - Dry-run mode to preview changes
   - Verbose mode for debugging
   - Clear error messages

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow responsible disclosure practices:

### Where to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please report security issues via:

1. **Email**: security@[project-domain] (if project domain exists)
2. **Private vulnerability report**: Use GitHub's private vulnerability reporting feature (if enabled)
3. **Encrypted email**: PGP key available in `.well-known/security.txt`

### What to Include

Please include:

- **Description**: Clear description of the vulnerability
- **Impact**: Potential impact and attack scenarios
- **Reproduction**: Step-by-step instructions to reproduce
- **Affected versions**: Which versions are affected
- **Suggested fix**: If you have one (optional but helpful)
- **Your details**: How you'd like to be credited (optional)

### Example Report

```
Subject: [SECURITY] Command Injection in Interface Name Handling

Description:
The interface name parameter in repair_interfaces() does not properly
sanitize input, allowing command injection via crafted interface names.

Impact:
An attacker with local access could execute arbitrary commands with
root privileges by providing a malicious interface name.

Reproduction:
1. Run: sudo ./network-repair repair-network "eth0; rm -rf /"
2. Observe arbitrary command execution

Affected Versions: 1.0.0 and earlier

Suggested Fix:
Add proper input validation in src/utils/system.sh:sanitize_input()
to only allow alphanumeric characters, dash, and underscore.
```

## Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 5 business days
- **Status updates**: Every 7 days until resolution
- **Fix timeline**: Critical issues within 7 days, others within 30 days
- **Public disclosure**: After fix is released and deployed

## Security Disclosure Process

1. **Report received** → We acknowledge receipt within 48 hours
2. **Assessment** → We verify and assess severity (using CVSS v3.1)
3. **Development** → We develop and test a fix
4. **Private notification** → We notify affected users privately
5. **Public release** → We release patched version
6. **CVE assignment** → We request CVE if applicable
7. **Public disclosure** → We publish security advisory (coordinated with reporter)
8. **Credit** → We credit reporter in CHANGELOG and security advisory

## Severity Levels

We use CVSS v3.1 for severity assessment:

- **Critical (9.0-10.0)**: Fix within 24-48 hours
- **High (7.0-8.9)**: Fix within 7 days
- **Medium (4.0-6.9)**: Fix within 30 days
- **Low (0.1-3.9)**: Fix in next regular release

## Security Best Practices for Users

### Before Running

1. **Verify integrity**:
   ```bash
   # Check SHA256 checksums if provided
   sha256sum -c checksums.txt
   ```

2. **Review code**:
   ```bash
   # All code is open source - review before running with root
   less src/main.sh
   ```

3. **Use dry-run mode first**:
   ```bash
   # Preview changes without making them
   sudo ./network-repair --dry-run repair
   ```

### During Use

1. **Understand what it does**:
   - Read the documentation
   - Use verbose mode to see what's happening
   - Check backups before and after

2. **Limit exposure**:
   - Don't run on production systems without testing first
   - Use virtual machines for testing
   - Have a recovery plan

3. **Monitor changes**:
   ```bash
   # Check what was backed up
   ls -la ~/.network-repair-backups/

   # View logs
   tail -f /var/log/network-repair.log  # if LOG_TO_FILE=true
   ```

### After Use

1. **Verify system state**:
   ```bash
   # Check network is working
   ping -c 3 google.com

   # Verify DNS
   dig google.com

   # Check interfaces
   ip addr show
   ```

2. **Review changes**:
   ```bash
   # Compare before/after
   diff ~/.network-repair-backups/resolv.conf.20250122_143052 /etc/resolv.conf
   ```

## Known Security Considerations

### By Design

These are intentional design decisions, not vulnerabilities:

1. **Requires Root**: Many network operations require root privileges. This is necessary and expected.

2. **Modifies System Files**: The tool modifies `/etc/resolv.conf`, routing tables, etc. This is its purpose.

3. **Restarts Services**: May restart NetworkManager, systemd-resolved, etc. Required for repairs to take effect.

4. **No Authentication**: Local tool assumes user has physical/SSH access. Not designed for remote/untrusted use.

### Out of Scope

The following are out of scope for security reports:

- Theoretical attacks requiring physical access to an already-compromised system
- Social engineering attacks
- Attacks requiring user to intentionally run malicious code
- Issues in third-party tools we depend on (report to those projects)
- Denial of service via resource exhaustion (local tool, single-user)

## Security Changelog

### Version 1.0.0 (2025-01-22)

- Initial release with security-focused design
- Input sanitization for all user-provided values
- Automatic backups before file modifications
- Privilege checking and safe elevation
- No use of dangerous bash constructs (eval, etc.)
- Dry-run mode for safe preview

## Security Tooling

### Static Analysis

We welcome security-focused static analysis:

```bash
# ShellCheck (for bash)
shellcheck src/**/*.sh

# Syntax validation
find . -name "*.sh" -exec bash -n {} \;
```

### Fuzzing

If you want to fuzz-test the tool:

```bash
# Example: Test with random interface names
for i in {1..1000}; do
    random_input=$(head -c 20 /dev/urandom | base64 | tr -d '+/=')
    echo "Testing: $random_input"
    ./network-repair diagnose-network "$random_input" 2>&1 | grep -i "error\|crash\|segfault" || true
done
```

## Security Contacts

- **Security Email**: security@[project-domain]
- **Security.txt**: `.well-known/security.txt` (RFC 9116)
- **PGP Key**: See `.well-known/security.txt` for current key

## Hall of Fame

We maintain a security hall of fame to thank researchers who help improve security:

*No vulnerabilities reported yet. Be the first!*

## License

This security policy is licensed under CC0 1.0 Universal (Public Domain).

---

**Last Updated**: 2025-01-22
**Version**: 1.0.0
