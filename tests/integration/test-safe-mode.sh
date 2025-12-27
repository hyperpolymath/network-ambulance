#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Integration tests for safe mode functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "${SCRIPT_DIR}")")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Test: Default mode is safe (read-only)
test_default_safe_mode() {
    echo "Testing default safe mode..."

    local output
    output=$("${PROJECT_DIR}/network-repair" repair 2>&1) || true

    if echo "${output}" | grep -q "SAFE MODE\|--apply-fixes\|Repair Operation Blocked"; then
        print_result "PASS" "Default mode blocks repairs"
    else
        print_result "FAIL" "Default mode should block repairs"
    fi
}

# Test: Diagnose command works without flags
test_diagnose_works() {
    echo "Testing diagnose command..."

    if "${PROJECT_DIR}/network-repair" diagnose >/dev/null 2>&1; then
        print_result "PASS" "Diagnose command works without flags"
    else
        # Diagnose may return non-zero if issues found, but should run
        if "${PROJECT_DIR}/network-repair" diagnose 2>&1 | grep -q "Diagnostic\|DNS\|Interface"; then
            print_result "PASS" "Diagnose command runs (found issues)"
        else
            print_result "FAIL" "Diagnose command failed unexpectedly"
        fi
    fi
}

# Test: Individual repair commands blocked in safe mode
test_individual_repairs_blocked() {
    echo "Testing individual repair commands in safe mode..."

    local commands=("repair-dns" "repair-network" "repair-routing" "repair-nm")
    local all_passed=true

    for cmd in "${commands[@]}"; do
        local output
        output=$("${PROJECT_DIR}/network-repair" "${cmd}" 2>&1) || true

        if echo "${output}" | grep -q "SAFE MODE\|--apply-fixes\|Repair Operation Blocked"; then
            echo -e "  ${GREEN}✓${NC} ${cmd} blocked"
        else
            echo -e "  ${RED}✗${NC} ${cmd} not blocked"
            all_passed=false
        fi
    done

    if [[ "${all_passed}" == "true" ]]; then
        print_result "PASS" "All individual repair commands blocked in safe mode"
    else
        print_result "FAIL" "Some repair commands not blocked"
    fi
}

# Test: Dry-run mode shows what would be done
test_dry_run_mode() {
    echo "Testing dry-run mode..."

    local output
    output=$("${PROJECT_DIR}/network-repair" --dry-run repair 2>&1) || true

    if echo "${output}" | grep -qi "dry.run\|preview\|would"; then
        print_result "PASS" "Dry-run mode provides preview information"
    else
        # Dry-run should at least not fail with safe mode error
        if ! echo "${output}" | grep -q "Repair Operation Blocked"; then
            print_result "PASS" "Dry-run mode bypasses safe mode block"
        else
            print_result "FAIL" "Dry-run mode not working correctly"
        fi
    fi
}

# Test: --apply-fixes flag is recognized
test_apply_fixes_flag() {
    echo "Testing --apply-fixes flag recognition..."

    # This should not show the safe mode block
    local output
    output=$("${PROJECT_DIR}/network-repair" --apply-fixes --help 2>&1) || true

    # Just verify the flag is recognized (won't error)
    if ! echo "${output}" | grep -q "Unknown option.*apply-fixes"; then
        print_result "PASS" "--apply-fixes flag recognized"
    else
        print_result "FAIL" "--apply-fixes flag not recognized"
    fi
}

# Test: --diagnose-only flag works
test_diagnose_only_flag() {
    echo "Testing --diagnose-only flag..."

    if "${PROJECT_DIR}/network-repair" --diagnose-only diagnose >/dev/null 2>&1; then
        print_result "PASS" "--diagnose-only flag works"
    else
        local output
        output=$("${PROJECT_DIR}/network-repair" --diagnose-only diagnose 2>&1) || true
        if echo "${output}" | grep -q "Diagnostic"; then
            print_result "PASS" "--diagnose-only flag works (with output)"
        else
            print_result "FAIL" "--diagnose-only flag failed"
        fi
    fi
}

# Test: Help text mentions safe mode
test_help_mentions_safe_mode() {
    echo "Testing help text..."

    local help_output
    help_output=$("${PROJECT_DIR}/network-repair" --help 2>&1)

    local checks_passed=0

    if echo "${help_output}" | grep -qi "safe"; then
        ((checks_passed++))
    fi

    if echo "${help_output}" | grep -q "apply-fixes"; then
        ((checks_passed++))
    fi

    if echo "${help_output}" | grep -q "dry-run"; then
        ((checks_passed++))
    fi

    if [[ ${checks_passed} -ge 2 ]]; then
        print_result "PASS" "Help text documents safe mode features"
    else
        print_result "FAIL" "Help text missing safe mode documentation"
    fi
}

# Test: Deprecated --auto-repair shows warning
test_deprecated_auto_repair() {
    echo "Testing deprecated --auto-repair warning..."

    local output
    output=$("${PROJECT_DIR}/network-repair" --auto-repair --help 2>&1) || true

    if echo "${output}" | grep -qi "deprecated\|apply-fixes"; then
        print_result "PASS" "--auto-repair shows deprecation notice"
    else
        print_result "FAIL" "--auto-repair should show deprecation notice"
    fi
}

# Main test runner
main() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Safe Mode Integration Tests                          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    test_default_safe_mode
    test_diagnose_works
    test_individual_repairs_blocked
    test_dry_run_mode
    test_apply_fixes_flag
    test_diagnose_only_flag
    test_help_mentions_safe_mode
    test_deprecated_auto_repair

    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Safe Mode Test Summary                               ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Tests run:    ${TESTS_RUN}"
    echo -e "  ${GREEN}Tests passed: ${TESTS_PASSED}${NC}"
    echo -e "  ${RED}Tests failed: ${TESTS_FAILED}${NC}"
    echo ""

    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
