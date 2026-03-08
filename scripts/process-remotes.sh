#!/bin/sh
# ─────────────────────────────────────────────────────────────
# process-remotes.sh
# Processes all .zap files in Features/ and Services/ directories
# Usage:
#   sh scripts/process-remotes.sh [OPTIONS]
# Options:
#   --verbose       Show detailed zap output
#   --dry-run       Show which files would be processed without running zap
#   --watch         Watch for changes and reprocess (requires fswatch)
#   --help, -h      Show this help message
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
MAGENTA='\033[0;35m'
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Disable colors if not a TTY or NO_COLOR is set
if [ ! -t 1 ] || [ "${NO_COLOR:-}" = "1" ]; then
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' RESET='' BOLD='' DIM=''
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

print_dim() {
    printf "${DIM}%s${RESET}\n" "$1"
}

print_processing() {
    printf "${MAGENTA}⚙${RESET}  Processing: ${BOLD}%s${RESET}\n" "$1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    if ! command_exists zap; then
        print_error "zap is not installed"
        echo ""
        print_info "Install zap from: https://github.com/red-blox/zap"
        echo ""
        echo "Installation methods:"
        echo "  • Aftman: ${CYAN}aftman add red-blox/zap${RESET}"
        echo "  • Foreman: ${CYAN}foreman install red-blox/zap${RESET}"
        echo "  • Manual: Download from GitHub releases"
        exit 1
    fi
    
    if [ "$VERBOSE" = "true" ]; then
        local zap_version=$(zap --version 2>&1 || echo "unknown")
        print_info "zap version: ${zap_version}"
    fi
}

# Find all .zap files in Features and Services
find_zap_files() {
    local src_dir="$1"
    local zap_files=""
    
    # Check Features directory
    if [ -d "${src_dir}/features" ]; then
        local feature_zaps=$(find "${src_dir}/features" -type f -name "*.zap" 2>/dev/null || true)
        zap_files="${zap_files}${feature_zaps}"
    fi
    
    # Check Services directory
    if [ -d "${src_dir}/Services" ]; then
        local service_zaps=$(find "${src_dir}/Services" -type f -name "*.zap" 2>/dev/null || true)
        if [ -n "$zap_files" ] && [ -n "$service_zaps" ]; then
            zap_files="${zap_files}
${service_zaps}"
        else
            zap_files="${zap_files}${service_zaps}"
        fi
    fi
    
    echo "$zap_files"
}

# Process a single .zap file
process_zap_file() {
    local file="$1"
    local relative_path=$(echo "$file" | sed "s|${PROJECT_ROOT}/||")
    
    print_processing "$relative_path"
    
    if [ "$DRY_RUN" = "true" ]; then
        print_dim "  [Dry run - would execute: zap \"$file\"]"
        return 0
    fi
    
    # Run zap
    if [ "$VERBOSE" = "true" ]; then
        if zap "$file"; then
            print_success "Processed: $relative_path"
        else
            print_error "Failed to process: $relative_path"
            return 1
        fi
    else
        # Capture output and only show on error
        local output=$(zap "$file" 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            print_success "Processed: $relative_path"
        else
            print_error "Failed to process: $relative_path"
            echo "$output" >&2
            return 1
        fi
    fi
}

# Show help message
# show_help() {
#     cat << EOF
# ${BOLD}process-remotes.sh${RESET}

# ${BOLD}DESCRIPTION${RESET}
#     Processes all .zap configuration files in Features/ and Services/ directories.
#     Recursively searches for .zap files and runs zap on each one.

# ${BOLD}USAGE${RESET}
#     sh scripts/process-remotes.sh [OPTIONS]

# ${BOLD}OPTIONS${RESET}
#     --verbose       Show detailed zap output for each file
#     --dry-run       List files that would be processed without running zap
#     --watch         Watch for changes and automatically reprocess (requires fswatch)
#     --help, -h      Show this help message

# ${BOLD}STRUCTURE${RESET}
#     The script searches for .zap files in:
#       src/features/*/      (e.g., src/features/Inventory/Inventory.zap)
#       src/Services/*/      (e.g., src/Services/DataService/DataService.zap)

# ${BOLD}EXAMPLES${RESET}
#     # Process all .zap files
#     sh scripts/process-remotes.sh

#     # See which files would be processed
#     sh scripts/process-remotes.sh --dry-run

#     # Process with detailed output
#     sh scripts/process-remotes.sh --verbose

#     # Watch for changes and auto-reprocess
#     sh scripts/process-remotes.sh --watch

# ${BOLD}REQUIREMENTS${RESET}
#     - zap: https://github.com/red-blox/zap
#     - fswatch (optional, for --watch): https://github.com/emcrisostomo/fswatch

# ${BOLD}INSTALLATION${RESET}
#     rokit add red-blox/zap

# EOF
# }
show_help() {
    printf "%b\n" "$(cat << EOF
${BOLD}process-remotes.sh${RESET}

${BOLD}DESCRIPTION${RESET}
    Processes all .zap configuration files in Features/ and Services/ directories.
    Recursively searches for .zap files and runs zap on each one.

${BOLD}USAGE${RESET}
    sh scripts/process-remotes.sh [OPTIONS]

${BOLD}OPTIONS${RESET}
    --verbose       Show detailed zap output for each file
    --dry-run       List files that would be processed without running zap
    --watch         Watch for changes and automatically reprocess (requires fswatch)
    --help, -h      Show this help message

${BOLD}STRUCTURE${RESET}
    The script searches for .zap files in:
      src/features/*/
      src/Services/*/

${BOLD}EXAMPLES${RESET}
    sh scripts/process-remotes.sh
    sh scripts/process-remotes.sh --dry-run
    sh scripts/process-remotes.sh --verbose
    sh scripts/process-remotes.sh --watch

${BOLD}REQUIREMENTS${RESET}
    - zap
    - fswatch (optional)

${BOLD}INSTALLATION${RESET}
    rokit add red-blox/zap
EOF
)"
}

# Watch mode
watch_mode() {
    if ! command_exists fswatch; then
        print_error "fswatch is not installed (required for --watch mode)"
        echo ""
        print_info "Install fswatch:"
        echo "  • macOS: ${CYAN}brew install fswatch${RESET}"
        echo "  • Linux: ${CYAN}apt install fswatch${RESET} or check your package manager"
        exit 1
    fi
    
    print_step "Starting watch mode..."
    print_info "Watching for changes to .zap files..."
    print_dim "Press Ctrl+C to stop"
    echo ""
    
    # Initial processing
    process_all_files
    
    # Watch for changes
    fswatch -0 -e ".*" -i "\\.zap$" "${PROJECT_ROOT}/src" | while read -d "" event; do
        echo ""
        print_info "Change detected: $(echo "$event" | sed "s|${PROJECT_ROOT}/||")"
        process_zap_file "$event" || true
    done
}

# Process all .zap files
process_all_files() {
    local zap_files=$(find_zap_files "$SRC_DIR")
    
    if [ -z "$zap_files" ]; then
        print_warning "No .zap files found in src/features/ or src/Services/"
        echo ""
        print_info "Expected structure:"
        print_dim "  src/features/FeatureName/FeatureName.zap"
        print_dim "  src/Services/ServiceName/ServiceName.zap"
        exit 0
    fi
    
    # Count files
    local file_count=$(echo "$zap_files" | grep -c . || echo "0")
    
    if [ "$DRY_RUN" = "true" ]; then
        print_step "Dry run - would process ${file_count} file(s):"
        echo ""
    else
        print_step "Found ${file_count} .zap file(s) to process"
        echo ""
    fi
    
    # Process each file
    local processed=0
    local failed=0
    
    echo "$zap_files" | while IFS= read -r file; do
        if [ -n "$file" ]; then
            if process_zap_file "$file"; then
                processed=$((processed + 1))
            else
                failed=$((failed + 1))
                if [ "$CONTINUE_ON_ERROR" = "false" ]; then
                    exit 1
                fi
            fi
        fi
    done
    
    # Check if the loop exited with error
    if [ $? -ne 0 ]; then
        echo ""
        print_error "Processing stopped due to error"
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────
# Parse Arguments
# ─────────────────────────────────────────────────────────────
VERBOSE=false
DRY_RUN=false
WATCH=false
CONTINUE_ON_ERROR=false

while [ $# -gt 0 ]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --watch|-w)
            WATCH=true
            shift
            ;;
        --continue-on-error)
            CONTINUE_ON_ERROR=true
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
SRC_DIR="${PROJECT_ROOT}/src"

if [ ! -d "$SRC_DIR" ]; then
    print_error "src/ directory not found at: $SRC_DIR"
    exit 1
fi

print_info "Project root: ${PROJECT_ROOT}"
echo ""

# Check dependencies
check_dependencies
echo ""

# Watch mode or single run
if [ "$WATCH" = "true" ]; then
    watch_mode
else
    process_all_files
    
    echo ""
    if [ "$DRY_RUN" = "false" ]; then
        print_success "All remotes successfully processed!"
    else
        print_info "Dry run complete"
    fi
fi