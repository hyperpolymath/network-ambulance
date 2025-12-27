#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Safe mode utilities - provides read-only diagnostic mode by default

# Safe mode configuration
# When true, repairs are blocked unless --apply-fixes is specified
SAFE_MODE="${SAFE_MODE:-true}"
APPLY_FIXES="${APPLY_FIXES:-false}"

# Check if apply-fixes mode is enabled
# Returns 0 if fixes can be applied, 1 if in safe mode
is_apply_fixes_enabled() {
    [[ "${APPLY_FIXES}" == "true" ]]
}

# Guard function to block repairs in safe mode
# Usage: require_apply_fixes "Description of what will be modified"
# Returns 0 if repairs can proceed, exits/returns 1 if blocked
require_apply_fixes() {
    local description="${1:-This operation}"

    if [[ "${APPLY_FIXES}" != "true" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_info "[DRY-RUN] Would perform: ${description}"
            return 0
        fi

        log_warn "[SAFE MODE] ${description} requires --apply-fixes flag"
        log_info "  Run with --apply-fixes to enable repairs"
        log_info "  Run with --dry-run to preview changes without applying"
        return 1
    fi

    return 0
}

# Display safe mode status
show_safe_mode_status() {
    if [[ "${APPLY_FIXES}" == "true" ]]; then
        log_warn "REPAIR MODE ENABLED - Changes will be applied to your system"
    elif [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "DRY-RUN MODE - Showing what would be done (no changes)"
    else
        log_info "SAFE MODE (read-only) - Running diagnostics only"
        log_info "  Use --apply-fixes to enable repairs"
        log_info "  Use --dry-run to preview changes"
    fi
}

# Display safe mode banner for repair commands
show_repair_blocked_banner() {
    echo ""
    log_section "Repair Operation Blocked"
    log_warn "This tool runs in SAFE MODE by default (read-only diagnostics)"
    echo ""
    log_info "To apply repairs, you must explicitly enable them:"
    echo ""
    echo "  $(basename "$0") --apply-fixes repair        # Apply all repairs"
    echo "  $(basename "$0") --apply-fixes repair-dns    # Apply DNS repairs only"
    echo "  $(basename "$0") --dry-run repair            # Preview repairs (no changes)"
    echo ""
    log_info "This safety measure prevents accidental system modifications."
    echo ""
}

# Summary of issues found in diagnostic mode with repair suggestions
show_diagnostic_repair_hint() {
    local issue_count="$1"

    if [[ ${issue_count} -gt 0 ]] && [[ "${APPLY_FIXES}" != "true" ]]; then
        echo ""
        log_section "Repair Options"
        log_info "Found ${issue_count} issue(s). To attempt repairs:"
        echo ""
        echo "  # Apply fixes automatically:"
        echo "  sudo $(basename "$0") --apply-fixes repair"
        echo ""
        echo "  # Preview what would be fixed:"
        echo "  $(basename "$0") --dry-run repair"
        echo ""
        echo "  # Interactive mode with confirmations:"
        echo "  sudo $(basename "$0") --apply-fixes --interactive"
        echo ""
    fi
}
