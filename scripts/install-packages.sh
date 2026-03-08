#!/bin/sh
# ─────────────────────────────────────────────────────────────
# install-packages.sh
# Installs wally packages and generates type definitions
# Usage:
#   sh scripts/install-packages.sh [OPTIONS]
# Options:
#   --clean     Remove existing packages before installing
#   --skip-types Skip type generation
#   --help      Show this help message
# ─────────────────────────────────────────────────────────────

set -e  # Exit on error
set -u  # Exit on undefined variable

# ─────────────────────────────────────────────────────────────
# Colors & Formatting
# ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'
BOLD='\033[1m'

# Check if terminal supports colors
if [ ! -t 1 ] || [ "${NO_COLOR:-}" = "1" ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    RESET=''
    BOLD=''
fi

# ─────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────
print_step() {
    printf "${BLUE}${BOLD}▶${RESET} ${BOLD}%s${RESET}\n" "$1"
}

print_success() {
    printf "${GREEN}✓${RESET} %s\n" "$1"
}

print_error() {
    printf "${RED}✗ Error:${RESET} %s\n" "$1" >&2
}

print_warning() {
    printf "${YELLOW}⚠ Warning:${RESET} %s\n" "$1"
}

print_info() {
    printf "${CYAN}ℹ${RESET} %s\n" "$1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required dependencies
check_dependencies() {
    local missing_deps=""

    if ! command_exists rokit; then
        missing_deps="${missing_deps}  - rokit (https://github.com/rojo-rbx/rokit)\n"
    fi
    
    if ! command_exists wally; then
        missing_deps="${missing_deps}  - wally (https://github.com/UpliftGames/wally)\n"
    fi
    
    if ! command_exists rojo; then
        missing_deps="${missing_deps}  - rojo (https://rojo.space)\n"
    fi
    
    if [ "$SKIP_TYPES" = "false" ] && ! command_exists wally-package-types; then
        missing_deps="${missing_deps}  - wally-package-types (https://github.com/JohnnyMorganz/wally-package-types)\n"
    fi
    
    if [ -n "$missing_deps" ]; then
        print_error "Missing required dependencies:"
        printf "${missing_deps}"
        exit 1
    fi
}

# Show help message
show_help() {
    printf "%b\n" "$(cat << EOF
${BOLD}install-packages.sh${RESET}

${BOLD}DESCRIPTION${RESET}
    Installs Wally packages and generates type definitions for Roblox development.

${BOLD}USAGE${RESET}
    sh scripts/install-packages.sh [OPTIONS]

${BOLD}OPTIONS${RESET}
    --clean         Remove existing packages and sourcemap before installing
    --skip-types    Skip type definition generation
    --help, -h      Show this help message

${BOLD}EXAMPLES${RESET}
    # Normal installation
    sh scripts/install-packages.sh

    # Clean install
    sh scripts/install-packages.sh --clean

    # Install without generating types
    sh scripts/install-packages.sh --skip-types

${BOLD}REQUIREMENTS${RESET}
    - rokit
    - wally
    - rojo
    - wally-package-types

EOF
)"
}

# ─────────────────────────────────────────────────────────────
# Parse Arguments
# ─────────────────────────────────────────────────────────────
CLEAN_INSTALL=false
SKIP_TYPES=false

while [ $# -gt 0 ]; do
    case "$1" in
        --clean)
            CLEAN_INSTALL=true
            shift
            ;;
        --skip-types)
            SKIP_TYPES=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ─────────────────────────────────────────────────────────────
# Main Script
# ─────────────────────────────────────────────────────────────

# Move to project root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

print_info "Project root: ${PROJECT_ROOT}"
echo ""

# Check dependencies
print_step "Checking dependencies..."
check_dependencies
print_success "All dependencies found"
echo ""

# Install Rokit tools
print_step "Intalling Rokit tools..."
if rokit install; then
    print_success "Rokit tools installed"
else
    print_error "Failed to install Rokit tools"
    exit 1
fi
echo ""

# Clean installation if requested
if [ "$CLEAN_INSTALL" = "true" ]; then
    print_step "Cleaning existing packages..."
    
    if [ -d "Packages" ]; then
        rm -rf Packages
        print_success "Removed Packages/"
    fi
    
    if [ -d "ServerPackages" ]; then
        rm -rf ServerPackages
        print_success "Removed ServerPackages/"
    fi
    
    if [ -f "sourcemap.json" ]; then
        rm -f sourcemap.json
        print_success "Removed sourcemap.json"
    fi
    
    echo ""
fi

# Install Wally packages
print_step "Installing Wally dependencies..."
if wally install; then
    print_success "Wally packages installed"
else
    print_error "Failed to install Wally packages"
    exit 1
fi
echo ""

# Generate sourcemap
print_step "Generating Rojo sourcemap..."
if [ ! -f "default.project.json" ]; then
    print_error "default.project.json not found"
    print_info "Make sure you're in the project root or run: node scripts/generateRojoTree.js"
    exit 1
fi

if rojo sourcemap default.project.json --output sourcemap.json; then
    print_success "Sourcemap generated"
else
    print_error "Failed to generate sourcemap"
    exit 1
fi
echo ""

# Generate type definitions
if [ "$SKIP_TYPES" = "false" ]; then
    print_step "Generating type definitions..."
    
    # Check if package directories exist
    if [ ! -d "Packages" ] && [ ! -d "ServerPackages" ]; then
        print_warning "No package directories found, skipping type generation"
    else
        # Generate types for Packages
        if [ -d "Packages" ]; then
            print_info "Processing Packages/..."
            if wally-package-types --sourcemap sourcemap.json Packages/; then
                print_success "Types generated for Packages/"
            else
                print_warning "Failed to generate types for Packages/"
            fi
        fi
        
        # Generate types for ServerPackages
        if [ -d "ServerPackages" ]; then
            print_info "Processing ServerPackages/..."
            if wally-package-types --sourcemap sourcemap.json ServerPackages/; then
                print_success "Types generated for ServerPackages/"
            else
                print_warning "Failed to generate types for ServerPackages/"
            fi
        fi
    fi
    echo ""
else
    print_info "Skipping type generation (--skip-types flag)"
    echo ""
fi

# Summary
echo "${GREEN}${BOLD}✅ Installation complete!${RESET}"