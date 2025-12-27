#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Run tests across multiple Linux distributions using containers
#
# Usage: ./run-container-tests.sh [distro] [--quick]
#
# Examples:
#   ./run-container-tests.sh              # Run all distros
#   ./run-container-tests.sh ubuntu       # Run only Ubuntu variants
#   ./run-container-tests.sh --quick      # Run quick test on one distro per family

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Container runtime (docker or podman)
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-docker}"

# Check for podman if docker not available
if ! command -v "${CONTAINER_RUNTIME}" &>/dev/null; then
    if command -v podman &>/dev/null; then
        CONTAINER_RUNTIME="podman"
    else
        echo -e "${RED}Error: Neither docker nor podman found${NC}"
        exit 1
    fi
fi

# Define distro test matrix
declare -A DISTROS=(
    # Debian family
    ["ubuntu-20.04"]="ubuntu:20.04"
    ["ubuntu-22.04"]="ubuntu:22.04"
    ["ubuntu-24.04"]="ubuntu:24.04"
    ["debian-11"]="debian:11"
    ["debian-12"]="debian:12"
    # RHEL family
    ["fedora-39"]="fedora:39"
    ["fedora-40"]="fedora:40"
    ["rockylinux-9"]="rockylinux:9"
    # Arch
    ["archlinux"]="archlinux:latest"
    # Alpine
    ["alpine-3.19"]="alpine:3.19"
    ["alpine-3.20"]="alpine:3.20"
    # openSUSE
    ["opensuse-leap"]="opensuse/leap:15.5"
    ["opensuse-tumbleweed"]="opensuse/tumbleweed:latest"
)

# Quick test selection (one per family)
QUICK_DISTROS=("ubuntu-22.04" "fedora-40" "archlinux" "alpine-3.20")

# Track results
declare -A RESULTS
TOTAL_PASSED=0
TOTAL_FAILED=0

# Get package install command for distro
get_install_cmd() {
    local image="$1"

    case "${image}" in
        ubuntu:*|debian:*)
            echo "apt-get update && apt-get install -y bash iproute2 iputils-ping dnsutils curl sudo procps"
            ;;
        fedora:*|rockylinux:*|almalinux:*)
            echo "dnf install -y bash iproute iputils bind-utils curl sudo procps-ng"
            ;;
        archlinux:*)
            echo "pacman -Syu --noconfirm && pacman -S --noconfirm bash iproute2 iputils bind curl sudo procps-ng"
            ;;
        alpine:*)
            echo "apk add --no-cache bash iproute2 iputils bind-tools curl sudo procps coreutils"
            ;;
        opensuse/*:*)
            echo "zypper --non-interactive install bash iproute2 iputils bind-utils curl sudo procps"
            ;;
        *)
            echo "echo 'Unknown distro'"
            ;;
    esac
}

# Run tests in a container
run_container_test() {
    local name="$1"
    local image="$2"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Testing: ${name} (${image})${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local install_cmd
    install_cmd=$(get_install_cmd "${image}")

    local test_script='
set -e
cd /opt/network-repair

# Make scripts executable
chmod +x network-repair src/main.sh
find src -name "*.sh" -exec chmod +x {} \;
find tests -name "*.sh" -exec chmod +x {} \;

echo "=== Syntax Check ==="
find . -name "*.sh" -type f ! -path "./.git/*" -exec bash -n {} \;
echo "Syntax OK"

echo ""
echo "=== Help Command ==="
./network-repair --help | head -20

echo ""
echo "=== Version Command ==="
./network-repair --version

echo ""
echo "=== Diagnostics (Safe Mode) ==="
./network-repair diagnose || true

echo ""
echo "=== Safe Mode Verification ==="
if ./network-repair repair 2>&1 | grep -q "SAFE MODE\|--apply-fixes\|Repair Operation Blocked"; then
    echo "✓ Safe mode correctly blocks repairs"
else
    echo "✗ Safe mode check failed"
    exit 1
fi

echo ""
echo "=== Test Suite ==="
./tests/run-tests.sh

echo ""
echo "All tests passed!"
'

    # Run container with tests
    if ${CONTAINER_RUNTIME} run --rm \
        -v "${PROJECT_DIR}:/opt/network-repair:ro" \
        "${image}" \
        /bin/bash -c "${install_cmd} && ${test_script}" 2>&1; then
        echo -e "${GREEN}✓ ${name} PASSED${NC}"
        RESULTS["${name}"]="PASSED"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        echo -e "${RED}✗ ${name} FAILED${NC}"
        RESULTS["${name}"]="FAILED"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi

    echo ""
}

# Print usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [DISTRO_FILTER]

Run tests across multiple Linux distributions using containers.

Options:
    -h, --help      Show this help message
    -q, --quick     Quick mode: test one distro per family
    -l, --list      List available distros

Distro Filters:
    ubuntu          Run Ubuntu variants only
    debian          Run Debian variants only
    fedora          Run Fedora/RHEL variants only
    arch            Run Arch Linux only
    alpine          Run Alpine variants only
    opensuse        Run openSUSE variants only
    all             Run all distros (default)

Examples:
    $(basename "$0")              # Run all distros
    $(basename "$0") ubuntu       # Run Ubuntu variants
    $(basename "$0") --quick      # Quick test mode

EOF
}

# List available distros
list_distros() {
    echo "Available distributions:"
    echo ""
    for name in "${!DISTROS[@]}"; do
        echo "  ${name}: ${DISTROS[${name}]}"
    done | sort
}

# Main function
main() {
    local quick_mode=false
    local filter="all"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -q|--quick)
                quick_mode=true
                shift
                ;;
            -l|--list)
                list_distros
                exit 0
                ;;
            *)
                filter="$1"
                shift
                ;;
        esac
    done

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Distribution Matrix Container Tests                      ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Container runtime: ${CONTAINER_RUNTIME}"
    echo -e "Mode: $(if ${quick_mode}; then echo "Quick"; else echo "Full"; fi)"
    echo -e "Filter: ${filter}"
    echo ""

    # Select distros to test
    local distros_to_test=()

    if ${quick_mode}; then
        distros_to_test=("${QUICK_DISTROS[@]}")
    else
        case "${filter}" in
            ubuntu)
                for name in "${!DISTROS[@]}"; do
                    [[ "${name}" == ubuntu-* ]] && distros_to_test+=("${name}")
                done
                ;;
            debian)
                for name in "${!DISTROS[@]}"; do
                    [[ "${name}" == debian-* ]] && distros_to_test+=("${name}")
                done
                ;;
            fedora|rhel)
                for name in "${!DISTROS[@]}"; do
                    [[ "${name}" == fedora-* || "${name}" == rockylinux-* ]] && distros_to_test+=("${name}")
                done
                ;;
            arch)
                distros_to_test+=("archlinux")
                ;;
            alpine)
                for name in "${!DISTROS[@]}"; do
                    [[ "${name}" == alpine-* ]] && distros_to_test+=("${name}")
                done
                ;;
            opensuse|suse)
                for name in "${!DISTROS[@]}"; do
                    [[ "${name}" == opensuse-* ]] && distros_to_test+=("${name}")
                done
                ;;
            all|*)
                distros_to_test=("${!DISTROS[@]}")
                ;;
        esac
    fi

    # Sort distros
    IFS=$'\n' distros_to_test=($(sort <<<"${distros_to_test[*]}")); unset IFS

    echo "Distros to test: ${distros_to_test[*]}"
    echo ""

    # Run tests
    for name in "${distros_to_test[@]}"; do
        if [[ -n "${DISTROS[${name}]:-}" ]]; then
            run_container_test "${name}" "${DISTROS[${name}]}"
        fi
    done

    # Print summary
    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Test Summary                                             ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    for name in "${!RESULTS[@]}"; do
        if [[ "${RESULTS[${name}]}" == "PASSED" ]]; then
            echo -e "  ${GREEN}✓${NC} ${name}"
        else
            echo -e "  ${RED}✗${NC} ${name}"
        fi
    done | sort

    echo ""
    echo -e "  Total: $((TOTAL_PASSED + TOTAL_FAILED))"
    echo -e "  ${GREEN}Passed: ${TOTAL_PASSED}${NC}"
    echo -e "  ${RED}Failed: ${TOTAL_FAILED}${NC}"
    echo ""

    if [[ ${TOTAL_FAILED} -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
