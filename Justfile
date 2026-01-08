# justfile - Task runner for Complete Linux Internet Repair Tool
# Install just: https://just.systems/

# Set shell to bash
set shell := ["bash", "-uc"]

# Default recipe (list all recipes)
default:
    @just --list

# ============================================================================
# DEVELOPMENT
# ============================================================================

# Run all pre-commit checks
check: syntax-check test lint

# Check bash syntax for all scripts
syntax-check:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔍 Checking bash syntax..."
    find . -name "*.sh" -type f -exec bash -n {} \;
    bash -n network-repair
    echo "✅ Syntax check passed"

# Run test suite
test:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧪 Running test suite..."
    chmod +x tests/*.sh
    ./tests/run-tests.sh

# Run utility tests
test-utils:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧪 Running utility tests..."
    chmod +x tests/test-utils.sh
    ./tests/test-utils.sh

# Lint shell scripts with ShellCheck (if available)
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v shellcheck >/dev/null 2>&1; then
        echo "🔍 Running ShellCheck..."
        find src -name "*.sh" -type f -exec shellcheck {} +
        echo "✅ Lint passed"
    else
        echo "⚠️  ShellCheck not installed (optional)"
        echo "   Install: apt-get install shellcheck"
    fi

# ============================================================================
# USAGE
# ============================================================================

# Run diagnostics (read-only, no root required)
diagnose:
    ./network-repair diagnose

# Run diagnostics with verbose output
diagnose-verbose:
    ./network-repair --verbose diagnose

# Run diagnostics for specific component
diagnose-dns:
    ./network-repair diagnose-dns

# Run diagnostics for network interfaces
diagnose-network:
    ./network-repair diagnose-network

# Run diagnostics for routing
diagnose-routing:
    ./network-repair diagnose-routing

# Show help
help:
    ./network-repair --help

# ============================================================================
# INSTALLATION
# ============================================================================

# Install system-wide (requires root)
install:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ${EUID} -ne 0 ]]; then
        echo "❌ Installation requires root privileges"
        echo "   Run: sudo just install"
        exit 1
    fi
    ./install.sh

# Uninstall (requires root)
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ${EUID} -ne 0 ]]; then
        echo "❌ Uninstallation requires root privileges"
        echo "   Run: sudo just uninstall"
        exit 1
    fi
    if [[ -x /opt/network-repair/uninstall.sh ]]; then
        /opt/network-repair/uninstall.sh
    else
        echo "❌ Tool not installed or uninstall script missing"
        exit 1
    fi

# ============================================================================
# DOCUMENTATION
# ============================================================================

# Generate documentation (markdown to man pages, if tools available)
docs:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v pandoc >/dev/null 2>&1; then
        echo "📚 Generating man pages..."
        mkdir -p docs/man
        pandoc README.md -s -t man -o docs/man/network-repair.1
        echo "✅ Man page generated: docs/man/network-repair.1"
    else
        echo "⚠️  pandoc not installed (optional)"
        echo "   Install: apt-get install pandoc"
    fi

# View README
readme:
    less README.md

# View troubleshooting guide
troubleshooting:
    less docs/troubleshooting.md

# View all documentation
docs-all:
    #!/usr/bin/env bash
    echo "📚 Available documentation:"
    echo "  - README.md"
    echo "  - CONTRIBUTING.md"
    echo "  - SECURITY.md"
    echo "  - CODE_OF_CONDUCT.md"
    echo "  - MAINTAINERS.md"
    echo "  - TPCF.md"
    echo "  - CHANGELOG.md"
    echo "  - docs/ARCHITECTURE.md"
    echo "  - docs/troubleshooting.md"
    echo "  - examples/basic-usage.md"
    echo "  - examples/advanced-usage.md"
    echo "  - RSR-COMPLIANCE.md"

# ============================================================================
# RELEASE
# ============================================================================

# Show current version
version:
    @grep '^VERSION=' src/main.sh | cut -d'"' -f2

# Create release archive
archive VERSION:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Creating release archive for v{{VERSION}}..."
    tar -czf "network-repair-{{VERSION}}.tar.gz" \
        --exclude='.git*' \
        --exclude='*.tar.gz' \
        --exclude='.github' \
        --transform "s,^,network-repair-{{VERSION}}/," \
        .
    sha256sum "network-repair-{{VERSION}}.tar.gz" > "network-repair-{{VERSION}}.tar.gz.sha256"
    echo "✅ Created: network-repair-{{VERSION}}.tar.gz"
    echo "✅ Checksum: network-repair-{{VERSION}}.tar.gz.sha256"

# ============================================================================
# VALIDATION
# ============================================================================

# Validate RSR compliance
validate-rsr:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔍 Validating RSR Compliance..."
    echo ""

    # Required files
    echo "📋 Checking required files..."
    required=(
        "README.md"
        "LICENSE"
        "CHANGELOG.md"
        "CONTRIBUTING.md"
        "CODE_OF_CONDUCT.md"
        "SECURITY.md"
        "MAINTAINERS.md"
        "TPCF.md"
        ".well-known/security.txt"
        ".well-known/ai.txt"
        ".well-known/humans.txt"
    )

    missing=0
    for file in "${required[@]}"; do
        if [[ -f "$file" ]]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file (missing)"
            missing=$((missing + 1))
        fi
    done

    echo ""
    echo "📊 RSR Compliance Summary:"
    echo "  Required files: $((${#required[@]} - missing))/${#required[@]}"

    if [[ $missing -eq 0 ]]; then
        echo "  🏆 RSR Level: Silver (100%)"
    else
        echo "  ⚠️  Missing $missing required file(s)"
    fi

    exit $missing

# Validate .well-known files
validate-wellknown:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔍 Validating .well-known files..."

    # Check security.txt
    if [[ -f .well-known/security.txt ]]; then
        if grep -q "Contact:" .well-known/security.txt && \
           grep -q "Expires:" .well-known/security.txt; then
            echo "  ✅ security.txt (RFC 9116 compliant)"
        else
            echo "  ⚠️  security.txt (missing required fields)"
        fi
    else
        echo "  ❌ security.txt (missing)"
    fi

    # Check ai.txt
    if [[ -f .well-known/ai.txt ]]; then
        echo "  ✅ ai.txt"
    else
        echo "  ❌ ai.txt (missing)"
    fi

    # Check humans.txt
    if [[ -f .well-known/humans.txt ]]; then
        echo "  ✅ humans.txt"
    else
        echo "  ❌ humans.txt (missing)"
    fi

# Run all validation checks
validate: validate-rsr validate-wellknown check

# ============================================================================
# CLEANUP
# ============================================================================

# Clean build artifacts and temporary files
clean:
    #!/usr/bin/env bash
    echo "🧹 Cleaning..."
    rm -f network-repair-*.tar.gz
    rm -f network-repair-*.tar.gz.sha256
    rm -rf docs/man
    find . -name "*.log" -type f -delete 2>/dev/null || true
    echo "✅ Clean complete"

# ============================================================================
# CONTINUOUS INTEGRATION
# ============================================================================

# Run CI checks (same as GitHub Actions)
ci: syntax-check test lint validate-rsr
    @echo "✅ All CI checks passed"

# ============================================================================
# STATISTICS
# ============================================================================

# Show project statistics
stats:
    #!/usr/bin/env bash
    echo "📊 Project Statistics"
    echo ""
    echo "Files:"
    echo "  Shell scripts: $(find . -name "*.sh" -type f | wc -l)"
    echo "  Markdown docs: $(find . -name "*.md" -type f | wc -l)"
    echo "  Total files:   $(find . -type f | wc -l)"
    echo ""
    echo "Lines of code:"
    find . -name "*.sh" -type f -exec wc -l {} + | tail -1
    echo ""
    echo "Git:"
    echo "  Commits: $(git rev-list --count HEAD 2>/dev/null || echo 'N/A')"
    echo "  Branch:  $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Version: $(grep '^VERSION=' src/main.sh | cut -d'"' -f2)"

# ============================================================================
# DEVELOPMENT HELPERS
# ============================================================================

# Watch files and run tests on change (requires entr)
watch:
    #!/usr/bin/env bash
    if command -v entr >/dev/null 2>&1; then
        find src tests -name "*.sh" | entr just test
    else
        echo "❌ entr not installed"
        echo "   Install: apt-get install entr"
        exit 1
    fi

# Format shell scripts (requires shfmt)
format:
    #!/usr/bin/env bash
    if command -v shfmt >/dev/null 2>&1; then
        echo "🎨 Formatting shell scripts..."
        find src tests -name "*.sh" -exec shfmt -w -i 4 {} +
        echo "✅ Formatting complete"
    else
        echo "⚠️  shfmt not installed (optional)"
        echo "   Install: go install mvdan.cc/sh/v3/cmd/shfmt@latest"
    fi

# ============================================================================
# HELP
# ============================================================================

# Show comprehensive help
help-all:
    @echo "Complete Linux Internet Repair Tool - justfile recipes"
    @echo ""
    @echo "📖 Usage: just <recipe>"
    @echo ""
    @just --list
    @echo ""
    @echo "💡 Quick start:"
    @echo "   just check       - Run all checks before commit"
    @echo "   just diagnose    - Run network diagnostics"
    @echo "   just test        - Run test suite"
    @echo "   just validate    - Validate RSR compliance"
    @echo "   sudo just install - Install system-wide"
    @echo ""
    @echo "📚 Documentation: just docs-all"
    @echo "🔍 Statistics:    just stats"
