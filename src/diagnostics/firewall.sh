#!/usr/bin/env bash
# Firewall diagnostics module

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"
source "${SCRIPT_DIR}/../utils/privileges.sh"

# Check iptables rules
check_iptables() {
    log_section "iptables Check"

    if ! command_exists iptables; then
        log_info "iptables not available"
        return 0
    fi

    log_step "Checking iptables rules"

    # Check if we have permissions
    if ! check_privileges; then
        log_warn "Root privileges required to check iptables"
        return 0
    fi

    # Check INPUT chain
    log_info "INPUT chain:"
    run_privileged iptables -L INPUT -n -v 2>/dev/null | head -20 | sed 's/^/  /' || log_warn "Cannot read INPUT chain"

    # Check OUTPUT chain
    log_info "OUTPUT chain:"
    run_privileged iptables -L OUTPUT -n -v 2>/dev/null | head -20 | sed 's/^/  /' || log_warn "Cannot read OUTPUT chain"

    # Check FORWARD chain
    log_info "FORWARD chain:"
    run_privileged iptables -L FORWARD -n -v 2>/dev/null | head -20 | sed 's/^/  /' || log_warn "Cannot read FORWARD chain"

    # Check for DROP/REJECT policies that might block traffic
    local policy_issues=0
    local output_policy
    output_policy=$(run_privileged iptables -L OUTPUT -n 2>/dev/null | grep "^Chain OUTPUT" | grep -o "policy [A-Z]*" | cut -d' ' -f2)

    if [[ "${output_policy}" == "DROP" ]] || [[ "${output_policy}" == "REJECT" ]]; then
        log_warn "OUTPUT chain policy is ${output_policy} - this may block outgoing traffic"
        policy_issues=$((policy_issues + 1))
    fi

    return ${policy_issues}
}

# Check nftables rules
check_nftables() {
    log_section "nftables Check"

    if ! command_exists nft; then
        log_info "nftables not available"
        return 0
    fi

    log_step "Checking nftables rules"

    if ! check_privileges; then
        log_warn "Root privileges required to check nftables"
        return 0
    fi

    local ruleset
    ruleset=$(run_privileged nft list ruleset 2>/dev/null)

    if [[ -z "${ruleset}" ]]; then
        log_info "No nftables rules configured"
        return 0
    fi

    echo "${ruleset}" | head -50 | sed 's/^/  /'

    return 0
}

# Check UFW (Uncomplicated Firewall)
check_ufw() {
    log_section "UFW Check"

    if ! command_exists ufw; then
        log_info "UFW not installed"
        return 0
    fi

    log_step "Checking UFW status"

    if ! check_privileges; then
        log_warn "Root privileges required to check UFW"
        return 0
    fi

    local ufw_status
    ufw_status=$(run_privileged ufw status 2>/dev/null)

    if echo "${ufw_status}" | grep -q "Status: active"; then
        log_info "UFW is active"
        echo "${ufw_status}" | sed 's/^/  /'

        # Check default policies
        local default_outgoing
        default_outgoing=$(run_privileged ufw status verbose 2>/dev/null | grep "Default:" | grep -o "outgoing ([a-z]*)" | cut -d'(' -f2 | tr -d ')')

        if [[ "${default_outgoing}" == "deny" ]]; then
            log_warn "UFW default outgoing policy is DENY - this may block internet"
            return 1
        fi
    else
        log_info "UFW is inactive"
    fi

    return 0
}

# Check firewalld
check_firewalld() {
    log_section "firewalld Check"

    if ! command_exists firewall-cmd; then
        log_info "firewalld not installed"
        return 0
    fi

    log_step "Checking firewalld status"

    if systemctl is-active --quiet firewalld 2>/dev/null; then
        log_info "firewalld is active"

        # Get default zone
        local default_zone
        default_zone=$(run_privileged firewall-cmd --get-default-zone 2>/dev/null)
        log_info "  Default zone: ${default_zone}"

        # Get active zones
        log_info "  Active zones:"
        run_privileged firewall-cmd --get-active-zones 2>/dev/null | sed 's/^/    /'

        # Check if outgoing is blocked
        local target
        target=$(run_privileged firewall-cmd --zone="${default_zone}" --get-target 2>/dev/null)
        log_info "  Zone target: ${target}"

        if [[ "${target}" == "DROP" ]] || [[ "${target}" == "REJECT" ]]; then
            log_warn "Zone target is ${target} - this may block traffic"
            return 1
        fi
    else
        log_info "firewalld is not active"
    fi

    return 0
}

# Main firewall diagnostic function
diagnose_firewall() {
    log_section "Firewall Diagnostics"

    local total_issues=0

    check_ufw
    total_issues=$((total_issues + $?))

    check_firewalld
    total_issues=$((total_issues + $?))

    check_iptables
    total_issues=$((total_issues + $?))

    check_nftables
    total_issues=$((total_issues + $?))

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "Firewall diagnostics completed with no issues"
        return 0
    else
        log_warn "Firewall diagnostics found ${total_issues} issue(s)"
        return 1
    fi
}
