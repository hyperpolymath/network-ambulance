#!/usr/bin/env bash
# Routing repair procedures

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"
source "${SCRIPT_DIR}/../utils/privileges.sh"

# Add default route
add_default_route() {
    local gateway="$1"
    local interface="$2"

    log_step "Adding default route"

    require_root "Adding routes requires root privileges"

    if [[ -z "${gateway}" ]] && [[ -z "${interface}" ]]; then
        log_error "Either gateway or interface must be specified"
        return 1
    fi

    # Build route command
    local route_cmd="ip route add default"

    if [[ -n "${gateway}" ]]; then
        route_cmd="${route_cmd} via ${gateway}"
    fi

    if [[ -n "${interface}" ]]; then
        route_cmd="${route_cmd} dev ${interface}"
    fi

    if run_privileged ${route_cmd}; then
        log_success "Default route added"
        return 0
    else
        log_error "Failed to add default route"
        return 1
    fi
}

# Remove duplicate default routes
remove_duplicate_routes() {
    log_section "Remove Duplicate Default Routes"

    require_root "Removing routes requires root privileges"

    # Get all default routes
    local default_routes
    mapfile -t default_routes < <(ip route show default 2>/dev/null)

    if [[ ${#default_routes[@]} -le 1 ]]; then
        log_info "No duplicate default routes found"
        return 0
    fi

    log_warn "Found ${#default_routes[@]} default routes"

    # Keep the first one, remove others
    local kept=0
    for route in "${default_routes[@]}"; do
        if [[ ${kept} -eq 0 ]]; then
            log_info "Keeping: ${route}"
            kept=1
        else
            log_step "Removing: ${route}"

            # Extract gateway and interface
            local gateway
            local interface
            gateway=$(echo "${route}" | grep -oP 'via \K[\d.]+')
            interface=$(echo "${route}" | grep -oP 'dev \K\S+')

            # Build delete command
            local del_cmd="ip route del default"
            if [[ -n "${gateway}" ]]; then
                del_cmd="${del_cmd} via ${gateway}"
            fi
            if [[ -n "${interface}" ]]; then
                del_cmd="${del_cmd} dev ${interface}"
            fi

            run_privileged ${del_cmd} && log_success "Removed duplicate route"
        fi
    done

    return 0
}

# Repair default route
repair_default_route() {
    log_section "Repair Default Route"

    require_root "Route repair requires root privileges"

    # Check if default route exists
    if ip route show default >/dev/null 2>&1; then
        log_info "Default route exists"

        # Remove duplicates
        remove_duplicate_routes

        # Test gateway
        local gateway
        gateway=$(ip route show default | grep -oP 'via \K[\d.]+' | head -1)

        if [[ -n "${gateway}" ]]; then
            log_step "Testing gateway ${gateway}"
            if ping -c 2 -W 2 "${gateway}" >/dev/null 2>&1; then
                log_success "Gateway is reachable"
                return 0
            else
                log_warn "Gateway is not reachable"
            fi
        fi

        return 0
    fi

    log_warn "No default route found"

    # Try to determine gateway from interface
    local primary
    primary=$(get_primary_interface)

    if [[ -z "${primary}" ]]; then
        log_error "No primary interface found, cannot determine gateway"
        return 1
    fi

    # Try to get gateway from DHCP
    log_step "Attempting to obtain gateway via DHCP"

    # Renew DHCP which should set up routes
    source "${SCRIPT_DIR}/interfaces.sh"
    if renew_dhcp "${primary}"; then
        sleep 2

        if ip route show default >/dev/null 2>&1; then
            log_success "Default route established via DHCP"
            return 0
        fi
    fi

    log_error "Failed to establish default route"
    return 1
}

# Flush and rebuild routing table
flush_routing_table() {
    log_section "Flush and Rebuild Routing Table"

    require_root "Flushing routes requires root privileges"

    log_warn "This will remove all routes and may temporarily disconnect network!"

    # Get primary interface before flushing
    local primary
    primary=$(get_primary_interface)

    if [[ -z "${primary}" ]]; then
        log_error "No primary interface found"
        return 1
    fi

    log_step "Flushing routing table"
    run_privileged ip route flush table main

    log_step "Rebuilding routes via DHCP"

    # Renew DHCP to rebuild routes
    source "${SCRIPT_DIR}/interfaces.sh"
    if renew_dhcp "${primary}"; then
        sleep 3

        if ip route show default >/dev/null 2>&1; then
            log_success "Routing table rebuilt successfully"
            return 0
        else
            log_error "Failed to rebuild routing table"
            return 1
        fi
    else
        log_error "Failed to renew DHCP"
        return 1
    fi
}

# Main routing repair function
repair_routing() {
    log_section "Routing Repair"

    require_root "Routing repair requires root privileges"

    local total_issues=0

    # First try gentle repairs
    repair_default_route
    total_issues=$((total_issues + $?))

    # If still broken, try more aggressive fix
    if [[ ${total_issues} -gt 0 ]]; then
        log_warn "Basic routing repair didn't fully resolve issues"

        # Ask before flushing (in interactive mode)
        if [[ "${INTERACTIVE:-false}" == "true" ]]; then
            read -p "Flush and rebuild routing table? This may temporarily disconnect network. (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                flush_routing_table
            fi
        fi
    fi

    # Final verification
    log_section "Routing Repair Verification"
    if ip route show default >/dev/null 2>&1; then
        local gateway
        gateway=$(ip route show default | grep -oP 'via \K[\d.]+' | head -1)

        if [[ -n "${gateway}" ]]; then
            if ping -c 2 -W 2 "${gateway}" >/dev/null 2>&1; then
                log_success "Routing repair completed successfully - gateway is reachable"
                return 0
            else
                log_warn "Default route exists but gateway is not reachable"
                return 1
            fi
        else
            log_success "Default route exists"
            return 0
        fi
    else
        log_error "Routing repair did not establish default route"
        return 1
    fi
}
