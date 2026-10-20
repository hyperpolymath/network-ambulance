#!/usr/bin/env bash
# Routing diagnostics module

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"

# Check routing table
check_routing_table() {
    log_section "Routing Table Check"

    local issues=0

    # Check for default route
    log_step "Checking default route"

    if ip route show default >/dev/null 2>&1; then
        local default_route
        default_route=$(ip route show default)
        log_success "Default route found"
        log_info "  ${default_route}"

        # Extract gateway
        local gateway
        gateway=$(echo "${default_route}" | grep -oP 'via \K[\d.]+' | head -1)
        if [[ -n "${gateway}" ]]; then
            log_info "  Gateway: ${gateway}"

            # Test gateway reachability
            log_step "Testing gateway reachability"
            if ping -c 2 -W 2 "${gateway}" >/dev/null 2>&1; then
                log_success "  Gateway ${gateway} is reachable"
            else
                log_error "  Gateway ${gateway} is NOT reachable"
                issues=$((issues + 1))
            fi
        fi
    else
        log_error "No default route found!"
        issues=$((issues + 1))
    fi

    # Show all routes
    log_step "All routes"
    ip route show 2>/dev/null | while read -r route; do
        log_info "  ${route}"
    done

    return ${issues}
}

# Check IPv6 routing
check_ipv6_routing() {
    log_section "IPv6 Routing Check"

    # Check if IPv6 is enabled
    if [[ ! -d /proc/sys/net/ipv6 ]]; then
        log_info "IPv6 is disabled"
        return 0
    fi

    log_step "IPv6 routes"
    local route_count
    route_count=$(ip -6 route show 2>/dev/null | wc -l)

    if [[ ${route_count} -eq 0 ]]; then
        log_warn "No IPv6 routes found"
        return 0
    fi

    ip -6 route show 2>/dev/null | while read -r route; do
        log_info "  ${route}"
    done

    # Check for IPv6 default route
    if ip -6 route show default >/dev/null 2>&1; then
        log_success "IPv6 default route found"
    else
        log_info "No IPv6 default route"
    fi

    return 0
}

# Check routing policy
check_routing_policy() {
    log_section "Routing Policy Check"

    log_step "Routing policy rules"

    if ip rule show >/dev/null 2>&1; then
        ip rule show 2>/dev/null | while read -r rule; do
            log_info "  ${rule}"
        done
    else
        log_warn "Cannot read routing policy"
    fi

    return 0
}

# Check for metric issues
check_route_metrics() {
    log_section "Route Metrics Check"

    log_step "Checking route metrics"

    # Get all default routes
    local default_routes
    mapfile -t default_routes < <(ip route show default 2>/dev/null)

    if [[ ${#default_routes[@]} -gt 1 ]]; then
        log_warn "Multiple default routes found:"
        for route in "${default_routes[@]}"; do
            log_info "  ${route}"
        done

        # Check if they have different metrics
        local has_metrics=0
        for route in "${default_routes[@]}"; do
            if echo "${route}" | grep -q "metric"; then
                has_metrics=1
                break
            fi
        done

        if [[ ${has_metrics} -eq 0 ]]; then
            log_warn "Multiple default routes without metrics may cause issues"
            return 1
        fi
    else
        log_success "Single default route configured"
    fi

    return 0
}

# Test route to internet
test_internet_route() {
    log_section "Internet Route Test"

    local test_hosts=("8.8.8.8" "1.1.1.1" "9.9.9.9")
    local issues=0

    for host in "${test_hosts[@]}"; do
        log_step "Tracing route to ${host}"

        # Try to get route
        if ip route get "${host}" >/dev/null 2>&1; then
            local route_info
            route_info=$(ip route get "${host}" 2>/dev/null | head -1)
            log_success "  ${route_info}"
        else
            log_error "  Cannot determine route to ${host}"
            issues=$((issues + 1))
        fi
    done

    return ${issues}
}

# Check ARP table
check_arp_table() {
    log_section "ARP Table Check"

    log_step "ARP entries"

    if command_exists ip; then
        local arp_count
        arp_count=$(ip neigh show 2>/dev/null | grep -v "FAILED" | wc -l)

        if [[ ${arp_count} -eq 0 ]]; then
            log_warn "No ARP entries found"
        else
            log_info "Found ${arp_count} ARP entries"
            ip neigh show 2>/dev/null | head -10 | while read -r entry; do
                log_info "  ${entry}"
            done
        fi
    fi

    return 0
}

# Main routing diagnostic function
diagnose_routing() {
    log_section "Routing Diagnostics"

    local total_issues=0

    check_routing_table
    total_issues=$((total_issues + $?))

    check_ipv6_routing
    total_issues=$((total_issues + $?))

    check_routing_policy

    check_route_metrics
    total_issues=$((total_issues + $?))

    test_internet_route
    total_issues=$((total_issues + $?))

    check_arp_table

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "Routing diagnostics completed with no issues"
        return 0
    else
        log_warn "Routing diagnostics found ${total_issues} issue(s)"
        return 1
    fi
}
