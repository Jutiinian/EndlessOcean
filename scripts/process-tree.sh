#!/bin/sh
# ─────────────────────────────────────────────────────────────
# process-tree.sh
# Generates Rojo project tree and sourcemap
# Usage:
#   sh scripts/process-tree.sh [OPTIONS]
# Options:
#   --skip-tree   Skip generateRojoTree.js
#   --skip-map    Skip sourcemap generation
#   --help, -h    Show this help message
# ─────────────────────────────────────────────────────────────

set -e
set -u

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

# Disable colors if unsupported
if [ ! -t 1 ] || [ "${NO_COLOR:-}" = "1" ]; then
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' RESET='' BOLD=''
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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────
# Dependency Check
# ─────────────────────────────────────────────────────────────
check_dependencies() {
    local missing=""

    command_exists node || missing="${missing}  - node\n"
    command_exists rojo || missing="${missing}  - rojo\n"

    if [ -n "$missing" ]; then
        print_error "Missing dependencies:"
        printf "%b" "$missing"
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────────────────────
show_help() {
    printf "%b\n" "$(cat << EOF
${BOLD}process-tree.sh${RESET}

${BOLD}DESCRIPTION${RESET}
    Generates the Rojo tree structure and sourcemap.

${BOLD}USAGE${RESET}
    sh scripts/process-tree.sh [OPTIONS]

${BOLD}OPTIONS${RESET}
    --skip-tree   Skip running generateRojoTree.js
    --skip-map    Skip sourcemap generation
    --help, -h    Show this help message

${BOLD}EXAMPLES${RESET}
    sh scripts/process-tree.sh
    sh scripts/process-tree.sh --skip-map

${BOLD}REQUIREMENTS${RESET}
    - node
    - rojo

EOF
)"
}

# ─────────────────────────────────────────────────────────────
# Parse Arguments
# ─────────────────────────────────────────────────────────────
SKIP_TREE=false
SKIP_MAP=false

while [ $# -gt 0 ]; do
    case "$1" in
        --skip-tree) SKIP_TREE=true ;;
        --skip-map)  SKIP_MAP=true ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
    shift
done

# ─────────────────────────────────────────────────────────────
# Main Script
# ─────────────────────────────────────────────────────────────

cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

print_info "Project root: $PROJECT_ROOT"
echo ""

check_dependencies
print_success "Dependencies OK"
echo ""

# Generate tree
if [ "$SKIP_TREE" = "false" ]; then
    print_step "Generating Rojo tree..."
    if node scripts/generateRojoTree.js; then
        print_success "Tree generated"
    else
        print_error "Tree generation failed"
        exit 1
    fi
    echo ""
else
    print_info "Skipping tree generation"
fi

# Generate sourcemap
if [ "$SKIP_MAP" = "false" ]; then
    if [ ! -f default.project.json ]; then
        print_error "default.project.json not found"
        exit 1
    fi

    print_step "Generating sourcemap..."
    if rojo sourcemap default.project.json --output sourcemap.json; then
        print_success "Sourcemap generated"
    else
        print_error "Sourcemap failed"
        exit 1
    fi
    echo ""
else
    print_info "Skipping sourcemap generation"
fi

print_success "Tree processing complete!"