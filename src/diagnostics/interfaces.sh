#!/usr/bin/env bash
# Network interface diagnostics module

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"

# Check network interfaces
check_interfaces() {
    log_section "Network Interface Check"

    local issues=0

    # List all interfaces
    log_step "Available network interfaces"
    local interfaces
    mapfile -t interfaces < <(get_all_interfaces)

    if [[ ${#interfaces[@]} -eq 0 ]]; then
        log_error "No network interfaces found!"
        return 1
    fi

    for iface in "${interfaces[@]}"; do
        log_info "  ${iface}"

        # Check if interface is up
        if interface_is_up "${iface}"; then
            log_success "    Status: UP"
        else
            log_warn "    Status: DOWN"
            issues=$((issues + 1))
        fi

        # Check IP address
        local ip
        ip=$(get_interface_ip "${iface}")
        if [[ -n "${ip}" ]]; then
            log_info "    IP: ${ip}"
        else
            log_warn "    IP: Not assigned"
        fi

        # Check MAC address
        local mac
        mac=$(cat /sys/class/net/"${iface}"/address 2>/dev/null)
        if [[ -n "${mac}" ]]; then
            log_info "    MAC: ${mac}"
        fi

        # Check driver
        local driver
        if [[ -d "/sys/class/net/${iface}/device/driver" ]]; then
            driver=$(readlink /sys/class/net/"${iface}"/device/driver 2>/dev/null | xargs basename)
            if [[ -n "${driver}" ]]; then
                log_info "    Driver: ${driver}"
            fi
        fi

        # Check link status
        if [[ -f "/sys/class/net/${iface}/carrier" ]]; then
            local carrier
            carrier=$(cat /sys/class/net/"${iface}"/carrier 2>/dev/null)
            if [[ "${carrier}" == "1" ]]; then
                log_success "    Link: Connected"
            else
                log_warn "    Link: Disconnected"
            fi
        fi
    done

    return ${issues}
}

# Check primary interface
check_primary_interface() {
    log_section "Primary Interface Check"

    local primary
    primary=$(get_primary_interface)

    if [[ -z "${primary}" ]]; then
        log_error "No primary interface found (no default route)"
        return 1
    fi

    log_success "Primary interface: ${primary}"

    # Check if primary interface is up
    if ! interface_is_up "${primary}"; then
        log_error "Primary interface is DOWN"
        return 1
    fi

    # Check if primary interface has IP
    local ip
    ip=$(get_interface_ip "${primary}")
    if [[ -z "${ip}" ]]; then
        log_error "Primary interface has no IP address"
        return 1
    fi

    log_info "IP address: ${ip}"

    # Check link quality for wireless
    if [[ -d "/sys/class/net/${primary}/wireless" ]]; then
        log_step "Wireless interface detected"

        if command_exists iw; then
            local ssid
            ssid=$(iw dev "${primary}" info 2>/dev/null | grep "ssid" | cut -d' ' -f2-)
            if [[ -n "${ssid}" ]]; then
                log_info "  Connected to: ${ssid}"
            fi

            # Get signal strength
            local signal
            signal=$(iw dev "${primary}" station dump 2>/dev/null | grep "signal:" | awk '{print $2}')
            if [[ -n "${signal}" ]]; then
                log_info "  Signal: ${signal} dBm"
            fi
        fi
    fi

    return 0
}

# Check interface statistics
check_interface_stats() {
    log_section "Interface Statistics"

    local primary
    primary=$(get_primary_interface)

    if [[ -z "${primary}" ]]; then
        log_warn "No primary interface to check"
        return 0
    fi

    log_step "Statistics for ${primary}"

    # Get RX/TX stats
    local rx_bytes tx_bytes rx_packets tx_packets rx_errors tx_errors

    if [[ -d "/sys/class/net/${primary}/statistics" ]]; then
        rx_bytes=$(cat /sys/class/net/"${primary}"/statistics/rx_bytes 2>/dev/null)
        tx_bytes=$(cat /sys/class/net/"${primary}"/statistics/tx_bytes 2>/dev/null)
        rx_packets=$(cat /sys/class/net/"${primary}"/statistics/rx_packets 2>/dev/null)
        tx_packets=$(cat /sys/class/net/"${primary}"/statistics/tx_packets 2>/dev/null)
        rx_errors=$(cat /sys/class/net/"${primary}"/statistics/rx_errors 2>/dev/null)
        tx_errors=$(cat /sys/class/net/"${primary}"/statistics/tx_errors 2>/dev/null)

        # Convert bytes to human readable
        local rx_human tx_human
        rx_human=$(numfmt --to=iec-i --suffix=B "${rx_bytes}" 2>/dev/null || echo "${rx_bytes} bytes")
        tx_human=$(numfmt --to=iec-i --suffix=B "${tx_bytes}" 2>/dev/null || echo "${tx_bytes} bytes")

        log_info "  RX: ${rx_human} (${rx_packets} packets, ${rx_errors} errors)"
        log_info "  TX: ${tx_human} (${tx_packets} packets, ${tx_errors} errors)"

        # Check for errors
        if [[ ${rx_errors} -gt 100 ]] || [[ ${tx_errors} -gt 100 ]]; then
            log_warn "  High error count detected!"
            return 1
        fi
    fi

    return 0
}

# Check for interface conflicts
check_interface_conflicts() {
    log_section "Interface Conflict Check"

    local issues=0

    # Check for duplicate IPs
    log_step "Checking for duplicate IP addresses"

    declare -A ip_map
    local interfaces
    mapfile -t interfaces < <(get_all_interfaces)

    for iface in "${interfaces[@]}"; do
        local ip
        ip=$(get_interface_ip "${iface}")

        if [[ -n "${ip}" ]]; then
            if [[ -n "${ip_map[${ip}]}" ]]; then
                log_error "  Duplicate IP ${ip} on ${iface} and ${ip_map[${ip}]}"
                issues=$((issues + 1))
            else
                ip_map[${ip}]="${iface}"
            fi
        fi
    done

    if [[ ${issues} -eq 0 ]]; then
        log_success "No duplicate IPs found"
    fi

    return ${issues}
}

# Main interface diagnostic function
diagnose_interfaces() {
    log_section "Network Interface Diagnostics"

    local total_issues=0

    check_interfaces
    total_issues=$((total_issues + $?))

    check_primary_interface
    total_issues=$((total_issues + $?))

    check_interface_stats
    total_issues=$((total_issues + $?))

    check_interface_conflicts
    total_issues=$((total_issues + $?))

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "Interface diagnostics completed with no issues"
        return 0
    else
        log_warn "Interface diagnostics found ${total_issues} issue(s)"
        return 1
    fi
}
