#!/usr/bin/env bash
# Connectivity diagnostics module

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"

# Test basic connectivity
test_basic_connectivity() {
    log_section "Basic Connectivity Test"

    local issues=0
    local test_hosts=("8.8.8.8" "1.1.1.1" "9.9.9.9")

    for host in "${test_hosts[@]}"; do
        log_step "Pinging ${host}"

        if ping -c 3 -W 3 "${host}" >/dev/null 2>&1; then
            # Get ping statistics
            local stats
            stats=$(ping -c 3 -W 3 "${host}" 2>/dev/null | tail -1)
            log_success "  ${host} is reachable - ${stats}"
        else
            log_error "  ${host} is NOT reachable"
            issues=$((issues + 1))
        fi
    done

    return ${issues}
}

# Test DNS-based connectivity
test_dns_connectivity() {
    log_section "DNS-based Connectivity Test"

    local issues=0
    local test_domains=("google.com" "cloudflare.com" "github.com")

    for domain in "${test_domains[@]}"; do
        log_step "Pinging ${domain}"

        # First try to resolve
        if ! check_dns "${domain}"; then
            log_error "  Cannot resolve ${domain}"
            issues=$((issues + 1))
            continue
        fi

        # Then ping
        if ping -c 2 -W 3 "${domain}" >/dev/null 2>&1; then
            log_success "  ${domain} is reachable"
        else
            log_warn "  ${domain} resolved but not pingable (may be blocked)"
        fi
    done

    return ${issues}
}

# Test HTTP/HTTPS connectivity
test_http_connectivity() {
    log_section "HTTP/HTTPS Connectivity Test"

    local issues=0

    if ! command_exists curl && ! command_exists wget; then
        log_warn "Neither curl nor wget available, skipping HTTP tests"
        return 0
    fi

    local test_urls=(
        "http://www.google.com"
        "https://www.cloudflare.com"
        "https://www.github.com"
    )

    for url in "${test_urls[@]}"; do
        log_step "Testing ${url}"

        if command_exists curl; then
            if timeout 10 curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null | grep -q "^[23]"; then
                log_success "  ${url} is accessible"
            else
                log_error "  ${url} is NOT accessible"
                issues=$((issues + 1))
            fi
        elif command_exists wget; then
            if timeout 10 wget -q --spider "${url}" 2>/dev/null; then
                log_success "  ${url} is accessible"
            else
                log_error "  ${url} is NOT accessible"
                issues=$((issues + 1))
            fi
        fi
    done

    return ${issues}
}

# Test port connectivity
test_port_connectivity() {
    log_section "Port Connectivity Test"

    local issues=0

    if ! command_exists nc && ! command_exists telnet; then
        log_warn "Neither nc nor telnet available, skipping port tests"
        return 0
    fi

    local test_ports=(
        "8.8.8.8:53:DNS"
        "1.1.1.1:53:DNS"
        "google.com:80:HTTP"
        "google.com:443:HTTPS"
    )

    for test in "${test_ports[@]}"; do
        IFS=: read -r host port service <<< "${test}"
        log_step "Testing ${service} (${host}:${port})"

        if command_exists nc; then
            if timeout 3 nc -z -w 2 "${host}" "${port}" 2>/dev/null; then
                log_success "  ${host}:${port} is reachable"
            else
                log_error "  ${host}:${port} is NOT reachable"
                issues=$((issues + 1))
            fi
        elif command_exists telnet; then
            if timeout 3 bash -c "echo quit | telnet ${host} ${port}" 2>&1 | grep -q "Connected"; then
                log_success "  ${host}:${port} is reachable"
            else
                log_error "  ${host}:${port} is NOT reachable"
                issues=$((issues + 1))
            fi
        fi
    done

    return ${issues}
}

# Test MTU
test_mtu() {
    log_section "MTU Test"

    local primary
    primary=$(get_primary_interface)

    if [[ -z "${primary}" ]]; then
        log_warn "No primary interface found"
        return 0
    fi

    # Get current MTU
    local mtu
    mtu=$(cat /sys/class/net/"${primary}"/mtu 2>/dev/null)

    log_info "Current MTU on ${primary}: ${mtu}"

    # Test with ping
    log_step "Testing MTU with ping"

    local test_sizes=(1500 1472 1400 1200)

    for size in "${test_sizes[@]}"; do
        # Subtract 28 bytes for IP + ICMP header
        local packet_size=$((size - 28))

        if ping -c 1 -W 2 -M do -s ${packet_size} 8.8.8.8 >/dev/null 2>&1; then
            log_success "  Packet size ${size} bytes: OK"
            break
        else
            log_warn "  Packet size ${size} bytes: Failed (may need lower MTU)"
        fi
    done

    return 0
}

# Test latency
test_latency() {
    log_section "Latency Test"

    local test_hosts=(
        "8.8.8.8:Google DNS"
        "1.1.1.1:Cloudflare DNS"
    )

    for test in "${test_hosts[@]}"; do
        IFS=: read -r host name <<< "${test}"
        log_step "Testing latency to ${name} (${host})"

        if ping -c 5 -W 3 "${host}" >/dev/null 2>&1; then
            local avg_latency
            avg_latency=$(ping -c 5 -W 3 "${host}" 2>/dev/null | tail -1 | cut -d'/' -f5)

            if [[ -n "${avg_latency}" ]]; then
                log_info "  Average latency: ${avg_latency} ms"

                # Check if latency is high
                local latency_int
                latency_int=$(echo "${avg_latency}" | cut -d'.' -f1)
                if [[ ${latency_int} -gt 200 ]]; then
                    log_warn "  High latency detected!"
                fi
            fi
        else
            log_error "  Cannot reach ${host}"
        fi
    done

    return 0
}

# Main connectivity diagnostic function
diagnose_connectivity() {
    log_section "Connectivity Diagnostics"

    local total_issues=0

    test_basic_connectivity
    total_issues=$((total_issues + $?))

    test_dns_connectivity
    total_issues=$((total_issues + $?))

    test_http_connectivity
    total_issues=$((total_issues + $?))

    test_port_connectivity
    total_issues=$((total_issues + $?))

    test_mtu

    test_latency

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "Connectivity diagnostics completed with no issues"
        return 0
    else
        log_warn "Connectivity diagnostics found ${total_issues} issue(s)"
        return 1
    fi
}
