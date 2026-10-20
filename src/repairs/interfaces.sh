#!/usr/bin/env bash
# Network interface repair procedures

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"
source "${SCRIPT_DIR}/../utils/privileges.sh"

# Bring up network interface
interface_up() {
    local interface="$1"

    log_step "Bringing up interface ${interface}"

    require_root "Interface operations require root privileges"

    if ! interface_exists "${interface}"; then
        log_error "Interface ${interface} does not exist"
        return 1
    fi

    if interface_is_up "${interface}"; then
        log_info "Interface ${interface} is already up"
        return 0
    fi

    if run_privileged ip link set "${interface}" up; then
        sleep 2

        if interface_is_up "${interface}"; then
            log_success "Interface ${interface} is now up"
            return 0
        else
            log_error "Interface ${interface} failed to come up"
            return 1
        fi
    else
        log_error "Failed to bring up interface ${interface}"
        return 1
    fi
}

# Restart network interface
restart_interface() {
    local interface="$1"

    log_section "Restart Interface ${interface}"

    require_root "Interface operations require root privileges"

    if ! interface_exists "${interface}"; then
        log_error "Interface ${interface} does not exist"
        return 1
    fi

    # Bring down
    log_step "Bringing down ${interface}"
    run_privileged ip link set "${interface}" down
    sleep 1

    # Bring up
    log_step "Bringing up ${interface}"
    if run_privileged ip link set "${interface}" up; then
        sleep 2

        if interface_is_up "${interface}"; then
            log_success "Interface ${interface} restarted successfully"
            return 0
        else
            log_error "Interface ${interface} failed to restart"
            return 1
        fi
    else
        log_error "Failed to restart interface ${interface}"
        return 1
    fi
}

# Renew DHCP lease
renew_dhcp() {
    local interface="${1:-$(get_primary_interface)}"

    log_section "Renew DHCP Lease"

    require_root "DHCP renewal requires root privileges"

    if [[ -z "${interface}" ]]; then
        log_error "No interface specified"
        return 1
    fi

    log_step "Renewing DHCP lease for ${interface}"

    # Try dhclient first
    if command_exists dhclient; then
        # Release current lease
        run_privileged dhclient -r "${interface}" 2>/dev/null || true
        sleep 1

        # Request new lease
        if run_privileged dhclient "${interface}"; then
            sleep 3
            log_success "DHCP lease renewed via dhclient"
            return 0
        fi
    fi

    # Try dhcpcd
    if command_exists dhcpcd; then
        if run_privileged dhcpcd -n "${interface}"; then
            sleep 3
            log_success "DHCP lease renewed via dhcpcd"
            return 0
        fi
    fi

    # Try systemd-networkd
    if command_exists networkctl; then
        run_privileged networkctl renew "${interface}" && {
            sleep 3
            log_success "DHCP lease renewed via networkctl"
            return 0
        }
    fi

    log_error "Failed to renew DHCP lease (no supported DHCP client found)"
    return 1
}

# Reset interface to DHCP
reset_interface_dhcp() {
    local interface="${1:-$(get_primary_interface)}"

    log_section "Reset Interface to DHCP"

    require_root "Interface reset requires root privileges"

    if [[ -z "${interface}" ]]; then
        log_error "No interface specified"
        return 1
    fi

    log_step "Flushing IP addresses from ${interface}"
    run_privileged ip addr flush dev "${interface}"

    log_step "Bringing interface down"
    run_privileged ip link set "${interface}" down
    sleep 1

    log_step "Bringing interface up"
    run_privileged ip link set "${interface}" up
    sleep 2

    log_step "Requesting DHCP lease"
    if renew_dhcp "${interface}"; then
        log_success "Interface ${interface} reset to DHCP"
        return 0
    else
        log_error "Failed to reset interface ${interface} to DHCP"
        return 1
    fi
}

# Repair all down interfaces
repair_down_interfaces() {
    log_section "Repair Down Interfaces"

    require_root "Interface repair requires root privileges"

    local interfaces
    mapfile -t interfaces < <(get_all_interfaces)

    local repaired=0

    for iface in "${interfaces[@]}"; do
        if ! interface_is_up "${iface}"; then
            log_step "Found down interface: ${iface}"

            if interface_up "${iface}"; then
                repaired=$((repaired + 1))
            fi
        fi
    done

    if [[ ${repaired} -gt 0 ]]; then
        log_success "Brought up ${repaired} interface(s)"
        return 0
    else
        log_info "No interfaces needed to be brought up"
        return 0
    fi
}

# Main interface repair function
repair_interfaces() {
    log_section "Network Interface Repair"

    require_root "Interface repair requires root privileges"

    local total_issues=0

    # Repair down interfaces
    repair_down_interfaces
    total_issues=$((total_issues + $?))

    # Check primary interface
    local primary
    primary=$(get_primary_interface)

    if [[ -z "${primary}" ]]; then
        log_warn "No primary interface found, attempting to configure first available interface"

        local interfaces
        mapfile -t interfaces < <(get_all_interfaces)

        if [[ ${#interfaces[@]} -gt 0 ]]; then
            primary="${interfaces[0]}"
            log_info "Using interface: ${primary}"

            # Try to bring it up and get DHCP
            interface_up "${primary}"
            renew_dhcp "${primary}"
        else
            log_error "No network interfaces available"
            return 1
        fi
    else
        # Primary interface exists, check if it has IP
        local ip
        ip=$(get_interface_ip "${primary}")

        if [[ -z "${ip}" ]]; then
            log_warn "Primary interface ${primary} has no IP address"

            # Try to renew DHCP
            renew_dhcp "${primary}"
            total_issues=$((total_issues + $?))
        fi
    fi

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "Interface repair completed successfully"
        return 0
    else
        log_warn "Interface repair completed with ${total_issues} issue(s)"
        return 1
    fi
}
