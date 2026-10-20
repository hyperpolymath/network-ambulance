#!/usr/bin/env bash
# Privilege checking and elevation utilities

# Check if running as root
is_root() {
    [[ ${EUID} -eq 0 ]]
}

# Check if sudo is available
has_sudo() {
    command -v sudo >/dev/null 2>&1
}

# Check if user has sudo privileges
can_sudo() {
    if ! has_sudo; then
        return 1
    fi
    sudo -n true 2>/dev/null
}

# Request root privileges
require_root() {
    local message="${1:-This operation requires root privileges}"

    if is_root; then
        return 0
    fi

    if ! has_sudo; then
        log_fatal "${message}. Please run as root or install sudo."
    fi

    log_warn "${message}"
    log_info "Requesting sudo access..."

    if ! sudo -v; then
        log_fatal "Failed to obtain sudo privileges"
    fi

    # Keep sudo alive in background
    ( while true; do sudo -n true; sleep 50; done 2>/dev/null ) &
    SUDO_KEEPER_PID=$!

    # Kill sudo keeper on exit
    trap "kill ${SUDO_KEEPER_PID} 2>/dev/null || true" EXIT
}

# Run command with appropriate privileges
run_privileged() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

# Check if we can run privileged commands
check_privileges() {
    if is_root; then
        log_debug "Running as root"
        return 0
    elif can_sudo; then
        log_debug "Can use sudo"
        return 0
    else
        log_error "No root privileges available"
        return 1
    fi
}
