#!/usr/bin/env bash
# DNS diagnostics module

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"

# Check DNS configuration
check_dns_config() {
    log_section "DNS Configuration Check"

    local issues=0

    # Check resolv.conf
    if [[ -f /etc/resolv.conf ]]; then
        log_step "Checking /etc/resolv.conf"

        # Check if it's a symlink
        if [[ -L /etc/resolv.conf ]]; then
            local target
            target="$(readlink -f /etc/resolv.conf)"
            log_info "  Symlink to: ${target}"
        fi

        # Check for nameservers
        local nameserver_count
        nameserver_count=$(grep -c "^nameserver" /etc/resolv.conf 2>/dev/null || echo 0)

        if [[ ${nameserver_count} -eq 0 ]]; then
            log_error "  No nameservers configured!"
            issues=$((issues + 1))
        else
            log_success "  Found ${nameserver_count} nameserver(s)"
            grep "^nameserver" /etc/resolv.conf | while read -r line; do
                log_info "    ${line}"
            done
        fi

        # Check file permissions
        local perms
        perms=$(stat -c %a /etc/resolv.conf 2>/dev/null)
        if [[ "${perms}" != "644" ]] && [[ "${perms}" != "444" ]]; then
            log_warn "  Unusual permissions: ${perms}"
        fi
    else
        log_error "/etc/resolv.conf not found!"
        issues=$((issues + 1))
    fi

    # Check systemd-resolved
    if command_exists resolvectl || command_exists systemd-resolve; then
        log_step "Checking systemd-resolved"

        if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
            log_success "  systemd-resolved is active"

            # Show DNS servers
            if command_exists resolvectl; then
                log_info "  DNS Servers:"
                resolvectl status 2>/dev/null | grep "DNS Servers:" -A 3 | sed 's/^/    /'
            fi
        else
            log_info "  systemd-resolved is not active"
        fi
    fi

    # Check NetworkManager DNS
    if command_exists nmcli; then
        log_step "Checking NetworkManager DNS settings"

        nmcli -t -f DEVICE,DNS device show 2>/dev/null | grep -v '^lo:' | while IFS=: read -r device dns; do
            if [[ -n "${dns}" ]]; then
                log_info "  ${device}: ${dns}"
            fi
        done
    fi

    return ${issues}
}

# Test DNS resolution
test_dns_resolution() {
    log_section "DNS Resolution Test"

    local issues=0
    local test_domains=("google.com" "cloudflare.com" "github.com")

    for domain in "${test_domains[@]}"; do
        log_step "Resolving ${domain}"

        if check_dns "${domain}"; then
            local ip
            if command_exists dig; then
                ip=$(dig +short "${domain}" 2>/dev/null | head -1)
            elif command_exists nslookup; then
                ip=$(nslookup "${domain}" 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}')
            else
                ip=$(getent hosts "${domain}" 2>/dev/null | awk '{print $1}')
            fi

            log_success "  Resolved to: ${ip}"
        else
            log_error "  Failed to resolve ${domain}"
            issues=$((issues + 1))
        fi
    done

    return ${issues}
}

# Test DNS servers directly
test_dns_servers() {
    log_section "DNS Server Test"

    local issues=0

    # Get nameservers from resolv.conf
    if [[ -f /etc/resolv.conf ]]; then
        local nameservers
        mapfile -t nameservers < <(grep "^nameserver" /etc/resolv.conf | awk '{print $2}')

        if [[ ${#nameservers[@]} -eq 0 ]]; then
            log_error "No nameservers found"
            return 1
        fi

        for ns in "${nameservers[@]}"; do
            log_step "Testing nameserver ${ns}"

            if command_exists dig; then
                if timeout 5 dig @"${ns}" google.com +short >/dev/null 2>&1; then
                    log_success "  ${ns} is responding"
                else
                    log_error "  ${ns} is not responding"
                    issues=$((issues + 1))
                fi
            elif command_exists nslookup; then
                if timeout 5 nslookup google.com "${ns}" >/dev/null 2>&1; then
                    log_success "  ${ns} is responding"
                else
                    log_error "  ${ns} is not responding"
                    issues=$((issues + 1))
                fi
            else
                log_warn "  No DNS query tools available to test ${ns}"
            fi
        done
    fi

    return ${issues}
}

# Check DNS cache
check_dns_cache() {
    log_section "DNS Cache Check"

    # Check systemd-resolved cache
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        log_step "systemd-resolved cache statistics"

        if command_exists resolvectl; then
            resolvectl statistics 2>/dev/null | sed 's/^/  /' || log_info "  Statistics not available"
        fi
    fi

    # Check nscd
    if systemctl is-active --quiet nscd 2>/dev/null; then
        log_info "nscd (Name Service Cache Daemon) is running"
    fi

    return 0
}

# Main DNS diagnostic function
diagnose_dns() {
    log_section "DNS Diagnostics"

    local total_issues=0

    check_dns_config
    total_issues=$((total_issues + $?))

    test_dns_resolution
    total_issues=$((total_issues + $?))

    test_dns_servers
    total_issues=$((total_issues + $?))

    check_dns_cache

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "DNS diagnostics completed with no issues"
        return 0
    else
        log_warn "DNS diagnostics found ${total_issues} issue(s)"
        return 1
    fi
}
