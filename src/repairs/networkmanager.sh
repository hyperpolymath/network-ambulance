#!/usr/bin/env bash
# NetworkManager repair procedures

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"
source "${SCRIPT_DIR}/../utils/privileges.sh"

# Restart NetworkManager
restart_networkmanager() {
    log_section "Restart NetworkManager"

    if ! command_exists nmcli; then
        log_info "NetworkManager not installed"
        return 0
    fi

    require_root "Restarting NetworkManager requires root privileges"

    log_step "Restarting NetworkManager service"

    if run_privileged systemctl restart NetworkManager; then
        sleep 3

        if systemctl is-active --quiet NetworkManager; then
            log_success "NetworkManager restarted successfully"

            # Wait for connections to come up
            log_step "Waiting for network connections..."
            sleep 5

            return 0
        else
            log_error "NetworkManager failed to start"
            return 1
        fi
    else
        log_error "Failed to restart NetworkManager"
        return 1
    fi
}

# Reconnect NetworkManager connection
reconnect_nm_connection() {
    log_section "Reconnect NetworkManager Connection"

    if ! command_exists nmcli; then
        log_info "NetworkManager not installed"
        return 0
    fi

    require_root "Reconnecting requires root privileges"

    # Get active connection
    local active_conn
    active_conn=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)

    if [[ -n "${active_conn}" ]]; then
        log_step "Reconnecting: ${active_conn}"

        # Disconnect
        run_privileged nmcli connection down "${active_conn}" 2>/dev/null || true
        sleep 2

        # Reconnect
        if run_privileged nmcli connection up "${active_conn}"; then
            log_success "Reconnected ${active_conn}"
            return 0
        else
            log_error "Failed to reconnect ${active_conn}"
            return 1
        fi
    else
        log_warn "No active connection to reconnect"

        # Try to connect to any available connection
        local available_conn
        available_conn=$(nmcli -t -f NAME connection show 2>/dev/null | head -1)

        if [[ -n "${available_conn}" ]]; then
            log_step "Connecting to: ${available_conn}"

            if run_privileged nmcli connection up "${available_conn}"; then
                log_success "Connected to ${available_conn}"
                return 0
            else
                log_error "Failed to connect to ${available_conn}"
                return 1
            fi
        else
            log_error "No connections available"
            return 1
        fi
    fi
}

# Enable NetworkManager on interface
enable_nm_on_interface() {
    local interface="${1:-$(get_primary_interface)}"

    log_section "Enable NetworkManager on Interface"

    if ! command_exists nmcli; then
        log_info "NetworkManager not installed"
        return 0
    fi

    require_root "Enabling NetworkManager requires root privileges"

    if [[ -z "${interface}" ]]; then
        log_error "No interface specified"
        return 1
    fi

    log_step "Enabling NetworkManager management for ${interface}"

    # Check if already managed
    if nmcli device show "${interface}" 2>/dev/null | grep -q "GENERAL.STATE.*connected"; then
        log_info "Interface ${interface} is already managed and connected"
        return 0
    fi

    # Set to managed
    if run_privileged nmcli device set "${interface}" managed yes; then
        sleep 2
        log_success "Interface ${interface} is now managed by NetworkManager"

        # Try to connect
        run_privileged nmcli device connect "${interface}" && log_success "Interface ${interface} connected"

        return 0
    else
        log_error "Failed to enable NetworkManager management for ${interface}"
        return 1
    fi
}

# Repair NetworkManager conflicts
repair_nm_conflicts() {
    log_section "Repair NetworkManager Conflicts"

    if ! command_exists nmcli; then
        log_info "NetworkManager not installed"
        return 0
    fi

    require_root "Repairing conflicts requires root privileges"

    local issues_fixed=0

    # Check for systemd-networkd conflict
    if systemctl is-active --quiet systemd-networkd 2>/dev/null; then
        log_warn "systemd-networkd is active and may conflict with NetworkManager"

        if [[ "${INTERACTIVE:-false}" == "true" ]]; then
            read -p "Stop systemd-networkd? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_step "Stopping systemd-networkd"
                run_privileged systemctl stop systemd-networkd
                run_privileged systemctl disable systemd-networkd
                log_success "systemd-networkd stopped and disabled"
                issues_fixed=$((issues_fixed + 1))
            fi
        else
            log_info "Run with --interactive to resolve conflicts"
        fi
    fi

    if [[ ${issues_fixed} -gt 0 ]]; then
        # Restart NetworkManager to take over
        restart_networkmanager
    fi

    return 0
}

# Reset NetworkManager connection
reset_nm_connection() {
    local connection="${1}"

    log_section "Reset NetworkManager Connection"

    if ! command_exists nmcli; then
        log_info "NetworkManager not installed"
        return 0
    fi

    require_root "Resetting connection requires root privileges"

    if [[ -z "${connection}" ]]; then
        # Get active connection
        connection=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)
    fi

    if [[ -z "${connection}" ]]; then
        log_error "No connection specified or found"
        return 1
    fi

    log_step "Deleting connection: ${connection}"

    local interface
    interface=$(nmcli -t -f DEVICE connection show "${connection}" 2>/dev/null | grep "^GENERAL.DEVICES:" | cut -d: -f2)

    # Delete connection
    if run_privileged nmcli connection delete "${connection}"; then
        log_success "Connection deleted"

        sleep 2

        # Create new connection
        if [[ -n "${interface}" ]]; then
            log_step "Creating new connection for ${interface}"

            if run_privileged nmcli connection add type ethernet ifname "${interface}" con-name "Wired-${interface}"; then
                log_success "New connection created"

                # Activate it
                run_privileged nmcli connection up "Wired-${interface}"

                return 0
            else
                log_error "Failed to create new connection"
                return 1
            fi
        fi

        return 0
    else
        log_error "Failed to delete connection"
        return 1
    fi
}

# Main NetworkManager repair function
repair_networkmanager() {
    log_section "NetworkManager Repair"

    if ! command_exists nmcli; then
        log_info "NetworkManager not installed, skipping repairs"
        return 0
    fi

    require_root "NetworkManager repair requires root privileges"

    local total_issues=0

    # Check if NetworkManager is running
    if ! systemctl is-active --quiet NetworkManager; then
        log_warn "NetworkManager is not running"

        log_step "Starting NetworkManager"
        if run_privileged systemctl start NetworkManager; then
            sleep 3
            log_success "NetworkManager started"
        else
            log_error "Failed to start NetworkManager"
            return 1
        fi
    fi

    # Repair conflicts
    repair_nm_conflicts

    # Check connectivity
    local connectivity
    connectivity=$(nmcli networking connectivity 2>/dev/null)

    case "${connectivity}" in
        full)
            log_success "Full connectivity via NetworkManager"
            return 0
            ;;
        limited|portal|none|unknown)
            log_warn "Limited or no connectivity: ${connectivity}"

            # Try reconnecting
            reconnect_nm_connection
            total_issues=$((total_issues + $?))

            # If still broken, restart NetworkManager
            if [[ ${total_issues} -gt 0 ]]; then
                restart_networkmanager
            fi
            ;;
    esac

    # Final verification
    log_section "NetworkManager Repair Verification"
    connectivity=$(nmcli networking connectivity 2>/dev/null)

    if [[ "${connectivity}" == "full" ]]; then
        log_success "NetworkManager repair completed successfully"
        return 0
    else
        log_warn "NetworkManager connectivity: ${connectivity}"
        return 1
    fi
}
