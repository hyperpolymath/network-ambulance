#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Network namespace utilities for safe network testing
#
# This module provides isolated network environments for testing
# without affecting the host system's network configuration.

set -euo pipefail

# Namespace prefix for test environments
NETNS_PREFIX="${NETNS_PREFIX:-netrepair-test}"

# Counter for unique namespace names
NETNS_COUNTER=0

# Track created namespaces for cleanup
declare -a CREATED_NAMESPACES=()

# Check if running with sufficient privileges for netns operations
check_netns_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo "Network namespace operations require root privileges" >&2
        return 1
    fi
    return 0
}

# Create a new isolated network namespace for testing
# Usage: create_test_netns [name]
# Returns: namespace name
create_test_netns() {
    local name="${1:-${NETNS_PREFIX}-${NETNS_COUNTER}}"
    NETNS_COUNTER=$((NETNS_COUNTER + 1))

    if ! check_netns_privileges; then
        return 1
    fi

    # Create the namespace
    ip netns add "${name}" 2>/dev/null || {
        echo "Failed to create network namespace: ${name}" >&2
        return 1
    }

    # Bring up loopback in the namespace
    ip netns exec "${name}" ip link set lo up 2>/dev/null || true

    CREATED_NAMESPACES+=("${name}")
    echo "${name}"
}

# Create a test namespace with simulated network interface
# Usage: create_test_netns_with_interface [name]
# Returns: namespace name
create_test_netns_with_interface() {
    local name="${1:-${NETNS_PREFIX}-iface-${NETNS_COUNTER}}"
    local veth_host="veth-${name}-h"
    local veth_ns="veth-${name}-n"

    if ! check_netns_privileges; then
        return 1
    fi

    # Create namespace
    local ns_name
    ns_name=$(create_test_netns "${name}")

    # Create veth pair
    ip link add "${veth_host}" type veth peer name "${veth_ns}" 2>/dev/null || {
        echo "Failed to create veth pair" >&2
        delete_test_netns "${ns_name}"
        return 1
    }

    # Move one end to namespace
    ip link set "${veth_ns}" netns "${ns_name}" 2>/dev/null || {
        echo "Failed to move veth to namespace" >&2
        ip link delete "${veth_host}" 2>/dev/null || true
        delete_test_netns "${ns_name}"
        return 1
    }

    # Configure interfaces
    ip addr add 10.200.1.1/24 dev "${veth_host}" 2>/dev/null || true
    ip link set "${veth_host}" up 2>/dev/null || true

    ip netns exec "${ns_name}" ip addr add 10.200.1.2/24 dev "${veth_ns}" 2>/dev/null || true
    ip netns exec "${ns_name}" ip link set "${veth_ns}" up 2>/dev/null || true

    echo "${ns_name}"
}

# Create a namespace with broken DNS for testing DNS repair
# Usage: create_broken_dns_netns [name]
create_broken_dns_netns() {
    local name="${1:-${NETNS_PREFIX}-brokendns-${NETNS_COUNTER}}"

    local ns_name
    ns_name=$(create_test_netns_with_interface "${name}")

    # Create a broken resolv.conf in the namespace
    mkdir -p "/etc/netns/${ns_name}" 2>/dev/null || true

    # Empty resolv.conf = broken DNS
    echo "# Intentionally broken DNS for testing" > "/etc/netns/${ns_name}/resolv.conf"

    echo "${ns_name}"
}

# Create a namespace with working DNS for testing
# Usage: create_working_dns_netns [name]
create_working_dns_netns() {
    local name="${1:-${NETNS_PREFIX}-workingdns-${NETNS_COUNTER}}"

    local ns_name
    ns_name=$(create_test_netns_with_interface "${name}")

    # Create working resolv.conf
    mkdir -p "/etc/netns/${ns_name}" 2>/dev/null || true
    cat > "/etc/netns/${ns_name}/resolv.conf" << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

    echo "${ns_name}"
}

# Delete a test namespace
# Usage: delete_test_netns <name>
delete_test_netns() {
    local name="$1"

    if [[ -z "${name}" ]]; then
        return 1
    fi

    # Remove namespace-specific config
    rm -rf "/etc/netns/${name}" 2>/dev/null || true

    # Delete veth interfaces (they get cleaned up automatically when namespace is deleted)
    ip link delete "veth-${name}-h" 2>/dev/null || true

    # Delete the namespace
    ip netns delete "${name}" 2>/dev/null || true
}

# Clean up all test namespaces
cleanup_all_test_netns() {
    for ns in "${CREATED_NAMESPACES[@]:-}"; do
        if [[ -n "${ns}" ]]; then
            delete_test_netns "${ns}"
        fi
    done
    CREATED_NAMESPACES=()

    # Also clean up any orphaned test namespaces
    for ns in $(ip netns list 2>/dev/null | grep "^${NETNS_PREFIX}" | awk '{print $1}'); do
        delete_test_netns "${ns}"
    done
}

# Run a command inside a network namespace
# Usage: run_in_netns <namespace> <command> [args...]
run_in_netns() {
    local ns="$1"
    shift

    if ! check_netns_privileges; then
        return 1
    fi

    ip netns exec "${ns}" "$@"
}

# Run the network repair tool inside a namespace
# Usage: run_repair_in_netns <namespace> [args...]
run_repair_in_netns() {
    local ns="$1"
    shift

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    run_in_netns "${ns}" "${script_dir}/network-repair" "$@"
}

# Check if a namespace exists
# Usage: netns_exists <name>
netns_exists() {
    local name="$1"
    ip netns list 2>/dev/null | grep -q "^${name}\$"
}

# Get interface status in namespace
# Usage: get_netns_interface_status <namespace> <interface>
get_netns_interface_status() {
    local ns="$1"
    local iface="$2"

    run_in_netns "${ns}" ip link show "${iface}" 2>/dev/null
}

# Set up trap to clean up on exit
setup_netns_cleanup_trap() {
    trap cleanup_all_test_netns EXIT INT TERM
}

# Export functions for use in tests
export -f create_test_netns
export -f create_test_netns_with_interface
export -f create_broken_dns_netns
export -f create_working_dns_netns
export -f delete_test_netns
export -f cleanup_all_test_netns
export -f run_in_netns
export -f run_repair_in_netns
export -f netns_exists
export -f setup_netns_cleanup_trap
