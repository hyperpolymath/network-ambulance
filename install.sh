#!/usr/bin/env bash
# Installation script for Complete Linux Internet Repair Tool

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="/opt/network-repair"
BIN_DIR="/usr/local/bin"
BIN_NAME="network-repair"

# Print colored message
print_msg() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Check if running as root
check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        print_msg "${RED}" "This installation script must be run as root"
        print_msg "${YELLOW}" "Please run: sudo $0"
        exit 1
    fi
}

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID}"
    else
        echo "unknown"
    fi
}

# Install dependencies
install_dependencies() {
    local distro
    distro=$(detect_distro)

    print_msg "${BLUE}" "Installing dependencies..."

    case "${distro}" in
        ubuntu|debian|linuxmint|pop)
            apt-get update
            apt-get install -y iproute2 iputils-ping dnsutils curl
            ;;
        fedora|rhel|centos|rocky|alma)
            dnf install -y iproute iputils bind-utils curl
            ;;
        arch|manjaro|endeavouros)
            pacman -S --noconfirm iproute2 iputils bind curl
            ;;
        opensuse*)
            zypper install -y iproute2 iputils bind-utils curl
            ;;
        *)
            print_msg "${YELLOW}" "Unknown distribution, skipping dependency installation"
            print_msg "${YELLOW}" "Please ensure these packages are installed:"
            print_msg "${YELLOW}" "  - iproute2 (ip command)"
            print_msg "${YELLOW}" "  - iputils (ping command)"
            print_msg "${YELLOW}" "  - dnsutils/bind-utils (dig command)"
            ;;
    esac

    print_msg "${GREEN}" "Dependencies installed"
}

# Create directories
create_directories() {
    print_msg "${BLUE}" "Creating installation directories..."

    mkdir -p "${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}/src"
    mkdir -p "${INSTALL_DIR}/config"

    print_msg "${GREEN}" "Directories created"
}

# Copy files
copy_files() {
    print_msg "${BLUE}" "Copying files..."

    # Copy source files
    cp -r src/* "${INSTALL_DIR}/src/"

    # Copy config
    cp -r config/* "${INSTALL_DIR}/config/"

    # Copy main wrapper
    cp network-repair "${INSTALL_DIR}/"

    # Copy documentation
    [[ -f README.adoc ]] && cp README.adoc "${INSTALL_DIR}/"
    [[ -f LICENSE ]] && cp LICENSE "${INSTALL_DIR}/"

    print_msg "${GREEN}" "Files copied"
}

# Set permissions
set_permissions() {
    print_msg "${BLUE}" "Setting permissions..."

    # Make scripts executable
    find "${INSTALL_DIR}/src" -name "*.sh" -exec chmod +x {} \;
    chmod +x "${INSTALL_DIR}/network-repair"

    # Set ownership
    chown -R root:root "${INSTALL_DIR}"

    print_msg "${GREEN}" "Permissions set"
}

# Create symlink
create_symlink() {
    print_msg "${BLUE}" "Creating symlink..."

    ln -sf "${INSTALL_DIR}/network-repair" "${BIN_DIR}/${BIN_NAME}"

    print_msg "${GREEN}" "Symlink created: ${BIN_DIR}/${BIN_NAME} -> ${INSTALL_DIR}/network-repair"
}

# Create uninstall script
create_uninstall() {
    print_msg "${BLUE}" "Creating uninstall script..."

    cat > "${INSTALL_DIR}/uninstall.sh" << 'EOF'
#!/usr/bin/env bash
# Uninstall script for Complete Linux Internet Repair Tool

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ ${EUID} -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}This will remove Complete Linux Internet Repair Tool${NC}"
read -p "Are you sure? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Remove symlink
rm -f /usr/local/bin/network-repair

# Remove installation directory
rm -rf /opt/network-repair

echo -e "${GREEN}Complete Linux Internet Repair Tool has been uninstalled${NC}"
EOF

    chmod +x "${INSTALL_DIR}/uninstall.sh"

    print_msg "${GREEN}" "Uninstall script created: ${INSTALL_DIR}/uninstall.sh"
}

# Main installation
main() {
    print_msg "${GREEN}" "╔════════════════════════════════════════════════════════╗"
    print_msg "${GREEN}" "║  Complete Linux Internet Repair Tool - Installer     ║"
    print_msg "${GREEN}" "╚════════════════════════════════════════════════════════╝"
    echo ""

    check_root

    print_msg "${BLUE}" "Detected distribution: $(detect_distro)"
    echo ""

    # Confirm installation
    print_msg "${YELLOW}" "This will install the tool to: ${INSTALL_DIR}"
    print_msg "${YELLOW}" "A symlink will be created at: ${BIN_DIR}/${BIN_NAME}"
    echo ""
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_msg "${YELLOW}" "Installation cancelled"
        exit 0
    fi

    echo ""

    # Run installation steps
    install_dependencies
    create_directories
    copy_files
    set_permissions
    create_symlink
    create_uninstall

    echo ""
    print_msg "${GREEN}" "╔════════════════════════════════════════════════════════╗"
    print_msg "${GREEN}" "║  Installation completed successfully!                 ║"
    print_msg "${GREEN}" "╚════════════════════════════════════════════════════════╝"
    echo ""
    print_msg "${BLUE}" "You can now run the tool with:"
    print_msg "${GREEN}" "  ${BIN_NAME} --help"
    print_msg "${GREEN}" "  ${BIN_NAME} diagnose"
    print_msg "${GREEN}" "  sudo ${BIN_NAME} repair"
    print_msg "${GREEN}" "  sudo ${BIN_NAME} interactive"
    echo ""
    print_msg "${BLUE}" "To uninstall, run:"
    print_msg "${YELLOW}" "  sudo ${INSTALL_DIR}/uninstall.sh"
    echo ""
}

main "$@"
