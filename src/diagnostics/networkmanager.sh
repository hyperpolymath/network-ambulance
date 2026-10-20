#!/usr/bin/env bash
# NetworkManager diagnostics module

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"

# Check NetworkManager status
check_nm_status() {
    log_section "NetworkManager Status Check"

    if ! command_exists nmcli; then
        log_info "NetworkManager not installed"
        return 0
    fi

    log_step "Checking NetworkManager service"

    if systemctl is-active --quiet NetworkManager 2>/dev/null; then
        log_success "NetworkManager is active"

        # Get version
        local version
        version=$(nmcli --version 2>/dev/null | head -1)
        log_info "  Version: ${version}"
    else
        log_error "NetworkManager is not active"
        return 1
    fi

    return 0
}

# Check NetworkManager connections
check_nm_connections() {
    log_section "NetworkManager Connections"

    if ! command_exists nmcli; then
        return 0
    fi

    log_step "Active connections"

    local connections
    connections=$(nmcli connection show --active 2>/dev/null)

    if [[ -z "${connections}" ]]; then
        log_warn "No active NetworkManager connections"
        return 1
    fi

    echo "${connections}" | sed 's/^/  /'

    return 0
}

# Check NetworkManager devices
check_nm_devices() {
    log_section "NetworkManager Devices"

    if ! command_exists nmcli; then
        return 0
    fi

    log_step "Device status"

    nmcli device status 2>/dev/null | sed 's/^/  /'

    # Check for disconnected devices
    local disconnected
    disconnected=$(nmcli device status 2>/dev/null | grep -c "disconnected")

    if [[ ${disconnected} -gt 0 ]]; then
        log_warn "${disconnected} device(s) disconnected"
    fi

    return 0
}

# Check NetworkManager general status
check_nm_general() {
    log_section "NetworkManager General Status"

    if ! command_exists nmcli; then
        return 0
    fi

    nmcli general status 2>/dev/null | sed 's/^/  /'

    # Check connectivity status
    local connectivity
    connectivity=$(nmcli networking connectivity 2>/dev/null)

    log_step "Connectivity check"

    case "${connectivity}" in
        full)
            log_success "  Full connectivity"
            ;;
        limited)
            log_warn "  Limited connectivity"
            return 1
            ;;
        portal)
            log_warn "  Captive portal detected"
            return 1
            ;;
        none)
            log_error "  No connectivity"
            return 1
            ;;
        unknown)
            log_warn "  Connectivity status unknown"
            ;;
    esac

    return 0
}

# Check NetworkManager configuration
check_nm_config() {
    log_section "NetworkManager Configuration"

    local nm_conf="/etc/NetworkManager/NetworkManager.conf"

    if [[ -f "${nm_conf}" ]]; then
        log_step "NetworkManager configuration (${nm_conf})"

        # Check for DNS settings
        if grep -q "dns=" "${nm_conf}" 2>/dev/null; then
            local dns_setting
            dns_setting=$(grep "dns=" "${nm_conf}" | head -1)
            log_info "  ${dns_setting}"
        fi

        # Check for managed setting
        if grep -q "managed=" "${nm_conf}" 2>/dev/null; then
            local managed
            managed=$(grep "managed=" "${nm_conf}" | head -1)
            log_info "  ${managed}"
        fi
    else
        log_info "NetworkManager configuration not found at ${nm_conf}"
    fi

    return 0
}

# Check for NetworkManager conflicts
check_nm_conflicts() {
    log_section "NetworkManager Conflict Check"

    local issues=0

    # Check for conflicts with systemd-networkd
    if systemctl is-active --quiet systemd-networkd 2>/dev/null; then
        log_warn "systemd-networkd is also active - may conflict with NetworkManager"
        issues=$((issues + 1))
    fi

    # Check for ifupdown conflicts
    if [[ -f /etc/network/interfaces ]]; then
        # Check if any interfaces are managed by ifupdown
        local managed_interfaces
        managed_interfaces=$(grep -E "^auto|^iface" /etc/network/interfaces 2>/dev/null | grep -v "^auto lo" | wc -l)

        if [[ ${managed_interfaces} -gt 0 ]]; then
            log_warn "/etc/network/interfaces has ${managed_interfaces} configured interface(s) - may conflict with NetworkManager"
            issues=$((issues + 1))
        fi
    fi

    if [[ ${issues} -eq 0 ]]; then
        log_success "No NetworkManager conflicts detected"
    fi

    return ${issues}
}

# Main NetworkManager diagnostic function
diagnose_networkmanager() {
    log_section "NetworkManager Diagnostics"

    # Check if NetworkManager is installed
    if ! command_exists nmcli; then
        log_info "NetworkManager is not installed, skipping diagnostics"
        return 0
    fi

    local total_issues=0

    check_nm_status
    total_issues=$((total_issues + $?))

    check_nm_connections
    total_issues=$((total_issues + $?))

    check_nm_devices

    check_nm_general
    total_issues=$((total_issues + $?))

    check_nm_config

    check_nm_conflicts
    total_issues=$((total_issues + $?))

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "NetworkManager diagnostics completed with no issues"
        return 0
    else
        log_warn "NetworkManager diagnostics found ${total_issues} issue(s)"
        return 1
    fi
}
