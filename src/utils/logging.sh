#!/usr/bin/env bash
# Logging utilities for network repair tool

# Source color utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/colors.sh"

# Log levels
declare -gA LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [FATAL]=4
)

# Current log level (default: INFO)
CURRENT_LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Log file location
LOG_FILE="${LOG_FILE:-/var/log/network-repair.log}"
LOG_TO_FILE="${LOG_TO_FILE:-false}"

# Enable verbose output
VERBOSE="${VERBOSE:-false}"

# Initialize logging
init_logging() {
    if [[ "${LOG_TO_FILE}" == "true" ]]; then
        # Create log directory if it doesn't exist
        local log_dir
        log_dir="$(dirname "${LOG_FILE}")"
        if [[ ! -d "${log_dir}" ]]; then
            mkdir -p "${log_dir}" 2>/dev/null || true
        fi

        # Try to create/touch log file
        if ! touch "${LOG_FILE}" 2>/dev/null; then
            # If we can't write to /var/log, use home directory
            LOG_FILE="${HOME}/.network-repair.log"
            touch "${LOG_FILE}" 2>/dev/null || LOG_TO_FILE="false"
        fi
    fi
}

# Check if we should log this level
should_log() {
    local level="$1"
    local current_level_num="${LOG_LEVELS[${CURRENT_LOG_LEVEL}]}"
    local message_level_num="${LOG_LEVELS[${level}]}"

    [[ ${message_level_num} -ge ${current_level_num} ]]
}

# Write to log file
write_log_file() {
    local message="$1"
    if [[ "${LOG_TO_FILE}" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
    fi
}

# Log debug message
log_debug() {
    local message="$*"
    if should_log "DEBUG" || [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${COLOR_DIM}[DEBUG]${COLOR_RESET} ${message}" >&2
        write_log_file "[DEBUG] ${message}"
    fi
}

# Log info message
log_info() {
    local message="$*"
    if should_log "INFO"; then
        echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} ${message}"
        write_log_file "[INFO] ${message}"
    fi
}

# Log success message
log_success() {
    local message="$*"
    echo -e "${COLOR_GREEN}[✓]${COLOR_RESET} ${message}"
    write_log_file "[SUCCESS] ${message}"
}

# Log warning message
log_warn() {
    local message="$*"
    if should_log "WARN"; then
        echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} ${message}" >&2
        write_log_file "[WARN] ${message}"
    fi
}

# Log error message
log_error() {
    local message="$*"
    if should_log "ERROR"; then
        echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} ${message}" >&2
        write_log_file "[ERROR] ${message}"
    fi
}

# Log fatal error and exit
log_fatal() {
    local message="$*"
    echo -e "${COLOR_RED}${COLOR_BOLD}[FATAL]${COLOR_RESET} ${message}" >&2
    write_log_file "[FATAL] ${message}"
    exit 1
}

# Log section header
log_section() {
    local title="$1"
    echo ""
    echo -e "${COLOR_CYAN}${COLOR_BOLD}=== ${title} ===${COLOR_RESET}"
    write_log_file "=== ${title} ==="
}

# Log step
log_step() {
    local step="$1"
    echo -e "${COLOR_BLUE}→${COLOR_RESET} ${step}"
    write_log_file "→ ${step}"
}

# Initialize logging on source
init_logging
