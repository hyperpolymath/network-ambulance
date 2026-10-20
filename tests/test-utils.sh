#!/usr/bin/env bash
# Utility function tests

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

source "${PROJECT_DIR}/src/utils/colors.sh"
source "${PROJECT_DIR}/src/utils/logging.sh"
source "${PROJECT_DIR}/src/utils/system.sh"

# Test colors
test_colors() {
    echo "Testing color utilities..."

    # Test that color variables are defined
    [[ -n "${COLOR_RED}" ]] || { echo "COLOR_RED not defined"; exit 1; }
    [[ -n "${COLOR_GREEN}" ]] || { echo "COLOR_GREEN not defined"; exit 1; }
    [[ -n "${COLOR_RESET}" ]] || { echo "COLOR_RESET not defined"; exit 1; }

    echo "✓ Color utilities work"
}

# Test logging
test_logging() {
    echo "Testing logging utilities..."

    # Test logging functions exist and work
    log_info "Test info message" >/dev/null
    log_debug "Test debug message" >/dev/null
    log_warn "Test warning message" 2>/dev/null
    log_error "Test error message" 2>/dev/null

    echo "✓ Logging utilities work"
}

# Test system detection
test_system() {
    echo "Testing system utilities..."

    # Test distro detection
    local distro
    distro=$(detect_distro)
    [[ -n "${distro}" ]] || { echo "Failed to detect distro"; exit 1; }
    echo "  Detected distro: ${distro}"

    # Test distro family detection
    local family
    family=$(detect_distro_family)
    [[ -n "${family}" ]] || { echo "Failed to detect distro family"; exit 1; }
    echo "  Detected family: ${family}"

    # Test network manager detection
    local nm
    nm=$(detect_network_manager)
    echo "  Detected network manager: ${nm}"

    echo "✓ System utilities work"
}

# Run all tests
main() {
    echo "Running utility function tests..."
    echo ""

    test_colors
    test_logging
    test_system

    echo ""
    echo "All utility tests passed!"
}

main "$@"
