#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Test runner for Complete Linux Internet Repair Tool

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Print test result
print_result() {
    local status="$1"
    local message="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "${status}" == "PASS" ]]; then
        echo -e "${GREEN}✓${NC} ${message}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} ${message}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run diagnostic tests
test_diagnostics() {
    echo -e "${BLUE}Testing Diagnostic Modules${NC}"
    echo ""

    # Test DNS diagnostics
    if bash -n "${PROJECT_DIR}/src/diagnostics/dns.sh" 2>/dev/null; then
        print_result "PASS" "DNS diagnostics syntax check"
    else
        print_result "FAIL" "DNS diagnostics syntax check"
    fi

    # Test interface diagnostics
    if bash -n "${PROJECT_DIR}/src/diagnostics/interfaces.sh" 2>/dev/null; then
        print_result "PASS" "Interface diagnostics syntax check"
    else
        print_result "FAIL" "Interface diagnostics syntax check"
    fi

    # Test routing diagnostics
    if bash -n "${PROJECT_DIR}/src/diagnostics/routing.sh" 2>/dev/null; then
        print_result "PASS" "Routing diagnostics syntax check"
    else
        print_result "FAIL" "Routing diagnostics syntax check"
    fi

    # Test connectivity diagnostics
    if bash -n "${PROJECT_DIR}/src/diagnostics/connectivity.sh" 2>/dev/null; then
        print_result "PASS" "Connectivity diagnostics syntax check"
    else
        print_result "FAIL" "Connectivity diagnostics syntax check"
    fi

    # Test firewall diagnostics
    if bash -n "${PROJECT_DIR}/src/diagnostics/firewall.sh" 2>/dev/null; then
        print_result "PASS" "Firewall diagnostics syntax check"
    else
        print_result "FAIL" "Firewall diagnostics syntax check"
    fi

    # Test NetworkManager diagnostics
    if bash -n "${PROJECT_DIR}/src/diagnostics/networkmanager.sh" 2>/dev/null; then
        print_result "PASS" "NetworkManager diagnostics syntax check"
    else
        print_result "FAIL" "NetworkManager diagnostics syntax check"
    fi

    echo ""
}

# Run repair tests
test_repairs() {
    echo -e "${BLUE}Testing Repair Modules${NC}"
    echo ""

    # Test DNS repairs
    if bash -n "${PROJECT_DIR}/src/repairs/dns.sh" 2>/dev/null; then
        print_result "PASS" "DNS repairs syntax check"
    else
        print_result "FAIL" "DNS repairs syntax check"
    fi

    # Test interface repairs
    if bash -n "${PROJECT_DIR}/src/repairs/interfaces.sh" 2>/dev/null; then
        print_result "PASS" "Interface repairs syntax check"
    else
        print_result "FAIL" "Interface repairs syntax check"
    fi

    # Test routing repairs
    if bash -n "${PROJECT_DIR}/src/repairs/routing.sh" 2>/dev/null; then
        print_result "PASS" "Routing repairs syntax check"
    else
        print_result "FAIL" "Routing repairs syntax check"
    fi

    # Test NetworkManager repairs
    if bash -n "${PROJECT_DIR}/src/repairs/networkmanager.sh" 2>/dev/null; then
        print_result "PASS" "NetworkManager repairs syntax check"
    else
        print_result "FAIL" "NetworkManager repairs syntax check"
    fi

    echo ""
}

# Run utility tests
test_utilities() {
    echo -e "${BLUE}Testing Utility Modules${NC}"
    echo ""

    # Test colors
    if bash -n "${PROJECT_DIR}/src/utils/colors.sh" 2>/dev/null; then
        print_result "PASS" "Colors utility syntax check"
    else
        print_result "FAIL" "Colors utility syntax check"
    fi

    # Test logging
    if bash -n "${PROJECT_DIR}/src/utils/logging.sh" 2>/dev/null; then
        print_result "PASS" "Logging utility syntax check"
    else
        print_result "FAIL" "Logging utility syntax check"
    fi

    # Test privileges
    if bash -n "${PROJECT_DIR}/src/utils/privileges.sh" 2>/dev/null; then
        print_result "PASS" "Privileges utility syntax check"
    else
        print_result "FAIL" "Privileges utility syntax check"
    fi

    # Test backup
    if bash -n "${PROJECT_DIR}/src/utils/backup.sh" 2>/dev/null; then
        print_result "PASS" "Backup utility syntax check"
    else
        print_result "FAIL" "Backup utility syntax check"
    fi

    # Test system
    if bash -n "${PROJECT_DIR}/src/utils/system.sh" 2>/dev/null; then
        print_result "PASS" "System utility syntax check"
    else
        print_result "FAIL" "System utility syntax check"
    fi

    # Test safemode
    if bash -n "${PROJECT_DIR}/src/utils/safemode.sh" 2>/dev/null; then
        print_result "PASS" "Safemode utility syntax check"
    else
        print_result "FAIL" "Safemode utility syntax check"
    fi

    echo ""
}

# Test main script
test_main() {
    echo -e "${BLUE}Testing Main Script${NC}"
    echo ""

    # Syntax check
    if bash -n "${PROJECT_DIR}/src/main.sh" 2>/dev/null; then
        print_result "PASS" "Main script syntax check"
    else
        print_result "FAIL" "Main script syntax check"
    fi

    # Test help output
    if "${PROJECT_DIR}/network-repair" --help >/dev/null 2>&1; then
        print_result "PASS" "Help command works"
    else
        print_result "FAIL" "Help command works"
    fi

    # Test version output
    if "${PROJECT_DIR}/network-repair" --version >/dev/null 2>&1; then
        print_result "PASS" "Version command works"
    else
        print_result "FAIL" "Version command works"
    fi

    echo ""
}

# Test installation script
test_installation() {
    echo -e "${BLUE}Testing Installation Script${NC}"
    echo ""

    # Syntax check
    if bash -n "${PROJECT_DIR}/install.sh" 2>/dev/null; then
        print_result "PASS" "Installation script syntax check"
    else
        print_result "FAIL" "Installation script syntax check"
    fi

    echo ""
}

# Test file permissions
test_permissions() {
    echo -e "${BLUE}Testing File Permissions${NC}"
    echo ""

    # Check if main script is executable
    if [[ -x "${PROJECT_DIR}/network-repair" ]]; then
        print_result "PASS" "Main wrapper is executable"
    else
        print_result "FAIL" "Main wrapper is executable"
    fi

    # Check if install script is executable
    if [[ -x "${PROJECT_DIR}/install.sh" ]]; then
        print_result "PASS" "Install script is executable"
    else
        print_result "FAIL" "Install script is executable"
    fi

    echo ""
}

# Test safe mode functionality
test_safe_mode() {
    echo -e "${BLUE}Testing Safe Mode${NC}"
    echo ""

    # Test that repairs are blocked by default
    local output
    output=$("${PROJECT_DIR}/network-repair" repair 2>&1) || true
    if echo "${output}" | grep -q "SAFE MODE\|--apply-fixes\|Repair Operation Blocked"; then
        print_result "PASS" "Repairs blocked in safe mode"
    else
        print_result "FAIL" "Repairs should be blocked in safe mode"
    fi

    # Test that diagnose works without flags
    if "${PROJECT_DIR}/network-repair" diagnose >/dev/null 2>&1 || \
       "${PROJECT_DIR}/network-repair" diagnose 2>&1 | grep -q "Diagnostic"; then
        print_result "PASS" "Diagnose works in safe mode"
    else
        print_result "FAIL" "Diagnose should work in safe mode"
    fi

    # Test that --apply-fixes is documented in help
    if "${PROJECT_DIR}/network-repair" --help 2>&1 | grep -q "apply-fixes"; then
        print_result "PASS" "--apply-fixes documented in help"
    else
        print_result "FAIL" "--apply-fixes should be in help"
    fi

    echo ""
}

# Main test function
main() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Complete Linux Internet Repair Tool - Test Suite    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    test_utilities
    test_diagnostics
    test_repairs
    test_main
    test_installation
    test_permissions
    test_safe_mode

    # Summary
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Test Summary                                         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Tests run:    ${TESTS_RUN}"
    echo -e "  ${GREEN}Tests passed: ${TESTS_PASSED}${NC}"

    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        echo -e "  ${RED}Tests failed: ${TESTS_FAILED}${NC}"
        echo ""
        exit 1
    else
        echo -e "  ${RED}Tests failed: ${TESTS_FAILED}${NC}"
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        echo ""
        exit 0
    fi
}

main "$@"
