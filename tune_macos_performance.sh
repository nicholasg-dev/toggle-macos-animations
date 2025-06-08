#!/bin/bash

# ======================================================================
# tune_macos_performance.sh - macOS Performance Optimization Script (v1.1)
# ======================================================================
#
# Description:
#   This script applies safe, reversible system-level optimizations and provides
#   critical recommendations to tune macOS for AI/ML development workloads.
#
# Key Changes in v1.1:
#   - REMOVED harmful tweaks (memory pressure disabling, TCP buffer tuning).
#   - REFINED cache clearing to be a recommendation instead of a destructive command.
#   - ADDED warnings and an optional prompt for the 'purge' command.
#   - ELEVATED critical manual recommendations for the largest performance gains.
#
# Features:
#   - UI/UX optimizations (reduces animations for a snappier feel)
#   - Targeted CPU and memory management tweaks
#   - Critical recommendations for GPU, Python, and Spotlight tuning
#
# Requirements:
#   - macOS 10.15 (Catalina) or later
#   - Administrator privileges (for system-level changes)
#
# Usage:
#   ./tune_macos_performance.sh [--apply|--backup|--restore|--help]
#
# Note:
#   - Always create a backup before applying changes.
#   - Review all changes before applying in production environments.
#
# Author: Nicholas G (Revised based on analysis)
# Version: 1.1.0
# Last Updated: 2025-05-27
# ======================================================================

# --- Global Variables ---
LOG_FILE="${HOME}/Library/Logs/macos_performance_tuning.log"
BACKUP_DIR="/Users/nicholas.gerasimatos/Library/Application Support/MacOSPerformanceTuning/backups"
BACKUP_FILE="${BACKUP_DIR}/defaults_backup_$(date +%Y%m%d_%H%M%S).plist"

# --- Logging Functions ---
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}" >&2
    exit 1
}

# --- Utility Functions ---

# Function to display usage
usage() {
    local exit_code=${1:-1}
    echo "Usage: $0 [OPTION]"
    echo "Tune macOS for AI/ML performance."
    echo ""
    echo "Options:"
    echo "  --apply    Apply safe optimizations and display critical recommendations."
    echo "  --backup   Backup current macOS defaults settings."
    echo "  --restore  Restore macOS defaults settings from the latest backup."
    echo "  --help     Display this help message."
    echo ""
    echo "Note: Applying optimizations will prompt for confirmation before making changes."
    exit "${exit_code}"
}

# Function to ask for user confirmation
confirm_action() {
    read -p "$1 (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0 # User confirmed
    else
        return 1 # User denied
    fi
}

# Function to backup a specific defaults setting
backup_defaults_setting() {
    local domain="$1"
    local key="$2"
    local type="$3" # e.g., -string, -int, -bool, -float
    local current_value

    if defaults read "${domain}" "${key}" &>/dev/null; then
        current_value=$(defaults read "${domain}" "${key}")
        echo "${domain} ${key} ${type} ${current_value}" >> "${BACKUP_FILE}"
        log_info "Backed up: ${domain} ${key} (Value: ${current_value})"
    else
        log_warn "Defaults key not found for backup: ${domain} ${key}"
    fi
}

# Function to backup all relevant defaults settings
backup_all_defaults() {
    log_info "Starting backup of macOS defaults settings to ${BACKUP_FILE}..."
    mkdir -p "${BACKUP_DIR}" || log_error "Failed to create backup directory: ${BACKUP_DIR}"
    touch "${BACKUP_FILE}" || log_error "Failed to create backup file: ${BACKUP_FILE}"

    # UI Animations - Comprehensive backup
    backup_defaults_setting com.apple.dock autohide-time-modifier -float
    backup_defaults_setting com.apple.dock autohide-delay -float
    backup_defaults_setting com.apple.dock expose-animation-duration -float
    backup_defaults_setting com.apple.dock springboard-show-duration -float
    backup_defaults_setting com.apple.dock springboard-hide-duration -float
    backup_defaults_setting com.apple.dock springboard-page-duration -float
    backup_defaults_setting com.apple.dock mineffect -string
    backup_defaults_setting com.apple.dock launchanim -bool
    backup_defaults_setting com.apple.dock workspaces-auto-swoosh -bool
    backup_defaults_setting com.apple.dock workspaces-edge-delay -float
    backup_defaults_setting NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool
    backup_defaults_setting NSGlobalDomain NSWindowResizeTime -float
    backup_defaults_setting NSGlobalDomain NSDocumentRevisionsDebugMode -bool
    backup_defaults_setting NSGlobalDomain NSBrowserColumnAnimationSpeedMultiplier -float
    backup_defaults_setting com.apple.finder DisableAllAnimations -bool
    backup_defaults_setting com.apple.finder FXEnableExtensionChangeWarning -bool
    backup_defaults_setting com.apple.mail DisableReplyAnimations -bool
    backup_defaults_setting com.apple.mail DisableSendAnimations -bool
    backup_defaults_setting com.apple.Safari WebKitInitialTimedLayoutDelay -float
    backup_defaults_setting com.apple.universalaccess reduceTransparency -bool
    backup_defaults_setting com.apple.universalaccess reduceMotion -bool
    backup_defaults_setting com.apple.Accessibility DifferentiateWithoutColor -bool
    backup_defaults_setting -g QLPanelAnimationDuration -float
    backup_defaults_setting com.apple.notificationcenterui bannerTime -float

    # DNS Caching
    backup_defaults_setting /Library/Preferences/com.apple.mDNSResponder.plist CacheTime -int

    log_success "Backup completed. Settings saved to ${BACKUP_FILE}"
}

# Function to restore defaults settings from a backup file
restore_all_defaults() {
    local latest_backup_file
    latest_backup_file=$(find "${BACKUP_DIR}" -name "defaults_backup_*.plist" -type f -exec ls -t {} + 2>/dev/null | head -n 1)

    if [[ -z "${latest_backup_file}" ]]; then
        log_error "No backup file found in ${BACKUP_DIR}. Please run with --backup first."
    fi

    log_info "Restoring macOS defaults settings from ${latest_backup_file}..."

    while IFS= read -r line; do
        local domain
        local key
        local type
        local value
        domain=$(echo "${line}" | awk '{print $1}')
        key=$(echo "${line}" | awk '{print $2}')
        type=$(echo "${line}" | awk '{print $3}')
        value=$(echo "${line}" | cut -d' ' -f4-)

        if [[ -n "${domain}" && -n "${key}" && -n "${type}" && -n "${value}" ]]; then
            log_info "Restoring: defaults write ${domain} ${key} ${type} ${value}"
            sudo defaults write "${domain}" "${key}" "${type}" "${value}" &>/dev/null
        else
            log_warn "Skipping malformed line in backup file: ${line}"
        fi
    done < "${latest_backup_file}"

    log_success "Defaults settings restored from ${latest_backup_file}."
    log_warn "Some restored changes might require a logout/login or reboot to take full effect."
}

# --- Automated Optimization Functions ---

# Function to completely disable all system animations
optimize_animations() {
    log_info "Completely disabling all system animations for maximum performance..."
    
    # Dock animations
    sudo defaults write com.apple.dock autohide-time-modifier -float 0
    sudo defaults write com.apple.dock autohide-delay -float 0
    sudo defaults write com.apple.dock expose-animation-duration -float 0
    sudo defaults write com.apple.dock springboard-show-duration -float 0
    sudo defaults write com.apple.dock springboard-hide-duration -float 0
    sudo defaults write com.apple.dock springboard-page-duration -float 0
    sudo defaults write com.apple.dock mineffect -string "scale"
    sudo defaults write com.apple.dock launchanim -bool false
    
    # Global window and application animations
    sudo defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    sudo defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    sudo defaults write NSGlobalDomain NSDocumentRevisionsDebugMode -bool true
    sudo defaults write NSGlobalDomain NSBrowserColumnAnimationSpeedMultiplier -float 0
    
    # Finder animations
    sudo defaults write com.apple.finder DisableAllAnimations -bool true
    sudo defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    
    # Mail animations
    sudo defaults write com.apple.mail DisableReplyAnimations -bool true
    sudo defaults write com.apple.mail DisableSendAnimations -bool true
    
    # Safari animations
    sudo defaults write com.apple.Safari WebKitInitialTimedLayoutDelay 0.25
    
    # System-wide visual effects
    sudo defaults write com.apple.universalaccess reduceTransparency -bool true
    sudo defaults write com.apple.universalaccess reduceMotion -bool true
    sudo defaults write com.apple.Accessibility DifferentiateWithoutColor -bool true
    
    # Launchpad animations
    sudo defaults write com.apple.dock springboard-show-duration -float 0
    sudo defaults write com.apple.dock springboard-hide-duration -float 0
    
    # Mission Control and Spaces animations
    sudo defaults write com.apple.dock workspaces-auto-swoosh -bool false
    sudo defaults write com.apple.dock workspaces-edge-delay -float 0
    
    # Quick Look animations
    sudo defaults write -g QLPanelAnimationDuration -float 0
    
    # Notification Center animations
    sudo defaults write com.apple.notificationcenterui bannerTime -float 0
    
    log_info "Restarting affected applications to apply animation changes..."
    killall Dock &>/dev/null
    killall Finder &>/dev/null
    killall NotificationCenter &>/dev/null
    killall SystemUIServer &>/dev/null
    log_success "All system animations completely disabled."
}

# Function to optimize CPU management
optimize_cpu_management() {
    log_info "Optimizing CPU management..."
    log_warn "Disabling Time Machine local snapshots can prevent background CPU/IO spikes but reduces on-the-go data recovery options."
    if confirm_action "Disable Time Machine local snapshots?"; then
        sudo tmutil disablelocal &>/dev/null
        log_success "Time Machine local snapshots disabled."
    else
        log_info "Skipped disabling Time Machine local snapshots."
    fi
}

# Function to optimize memory management
optimize_memory_management() {
    log_info "Optimizing memory management..."

    # Purge command with warning and confirmation
    log_warn "The 'purge' command frees up inactive RAM by clearing file system caches."
    log_warn "This can be counterproductive, as the OS may need to re-read that data from the much slower disk, temporarily hurting performance."
    log_warn "It is only useful before a specific memory-intensive benchmark, not for general use."
    if confirm_action "Run 'sudo purge' to clear inactive memory?"; then
        sudo purge
        log_success "Inactive memory and disk caches purged."
    else
        log_info "Skipped running 'purge'."
    fi

    # Increase shared memory limits (useful for Python multiprocessing, databases)
    log_info "Increasing shared memory limits (useful for Python multiprocessing)..."
    sudo sysctl -w kern.sysv.shmmax=4194304000  # 4GB
    sudo sysctl -w kern.sysv.shmall=1024000
    log_success "Shared memory limits increased. This will reset on reboot."
}

# Function to optimize storage (recommendations only)
optimize_storage_recommendations() {
    log_info "Providing storage optimization recommendations..."
    log_warn "Aggressively deleting cache files can degrade performance. Prefer targeted cleaning."
    log_info "Recommendation: Use 'brew cleanup' to clear outdated Homebrew files."
    log_info "Recommendation: Use 'pip cache purge' or 'conda clean --all' to clear package manager caches."
    log_info "Recommendation: Avoid running 'rm -rf ~/Library/Caches/*' as it forces apps to rebuild caches, slowing them down."
    log_success "Storage optimization recommendations provided."
}

# Function to optimize network settings
optimize_network() {
    log_info "Optimizing network settings..."
    log_warn "Modern macOS network stacks auto-tune well. Aggressive TCP tuning has been removed as it is often counterproductive."
    
    # Optimize DNS caching (a safe, minor tweak)
    log_info "Adjusting DNS cache settings for longer retention..."
    sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist CacheTime -int 259200 &>/dev/null # 72 hours
    log_success "DNS cache time increased."
    
    log_info "Flushing DNS cache to apply new settings..."
    sudo dscacheutil -flushcache &>/dev/null
    sudo killall -HUP mDNSResponder &>/dev/null
    log_success "DNS cache flushed."
}

# --- Critical Performance Recommendations (Manual Steps) ---

display_critical_recommendations() {
    log_info "\n======================================================================"
    log_info "--- CRITICAL PERFORMANCE RECOMMENDATIONS (MANUAL STEPS) ---"
    log_info "The following manual steps will provide the MOST significant performance"
    log_info "gains for AI/ML workloads. The automated tweaks above are secondary."
    log_info "======================================================================\n"

    # 1. GPU / Apple Silicon MPS
    log_info "1. GPU USAGE (Apple Silicon):"
    log_success "ACTION: Ensure your ML code uses the Metal Performance Shaders (MPS) backend."
    log_info "   - In PyTorch, check with 'torch.backends.mps.is_available()' and use '.to(\"mps\")'."
    log_info "   - This is the single most important optimization for training on Apple Silicon GPUs."
    log_info "   - Monitor GPU usage via Activity Monitor (Window -> GPU History).\n"

    # 2. Spotlight Indexing
    log_info "2. SPOTLIGHT INDEXING:"
    log_success "ACTION: Exclude development folders from Spotlight indexing."
    log_info "   - Background indexing of virtual environments, datasets, and build folders ('node_modules') consumes significant CPU/IO."
    log_info "   - Go to System Settings > Siri & Spotlight > Spotlight Privacy."
    log_info "   - Drag your main development folder (e.g., ~/dev, ~/Projects) into the list.\n"

    # 3. Python Environment Variables
    log_info "3. PYTHON CPU USAGE (OMP_NUM_THREADS):"
    log_success "ACTION: Set the OMP_NUM_THREADS environment variable to the number of physical CPU cores."
    log_info "   - This prevents CPU-bound libraries (NumPy, SciPy, Scikit-learn) from underutilizing your CPU."
    log_info "   - Add this to your shell profile (~/.zshrc, ~/.bash_profile):"
    log_warn "     export OMP_NUM_THREADS=$(sysctl -n hw.physicalcpu)\n"

    # 4. Resource Allocation
    log_info "4. PROCESS PRIORITY (nice/renice):"
    log_success "ACTION: Run critical training jobs with a higher priority."
    log_info "   - Use 'nice' to start a process with higher priority: 'nice -n -10 python train.py'"
    log_info "   - Use 'renice' to change a running process's priority: 'sudo renice -n -10 -p <PID>'\n"
}

# --- Main Script Execution ---
main() {
    if [[ "$#" -eq 0 || "$1" == "--help" ]]; then
        usage 0
    fi

    case "$1" in
        --apply)
            log_info "Attempting to apply macOS performance optimizations."
            if confirm_action "This script will apply system tweaks and show critical recommendations. Do you want to proceed?"; then
                backup_all_defaults

                log_info "\n--- Applying Automated System Tweaks ---"
                optimize_animations
                optimize_cpu_management
                optimize_memory_management
                optimize_network
                optimize_storage_recommendations # Now provides recommendations

                # The most important part is now displayed clearly at the end.
                display_critical_recommendations

                log_success "\nmacOS performance tuning script completed."
                log_info "Check ${LOG_FILE} for details."
                log_warn "Some changes might require a logout/login or reboot to take full effect."
            else
                log_info "Operation cancelled by user."
            fi
            ;;
        --backup)
            backup_all_defaults
            ;;
        --restore)
            restore_all_defaults
            ;;
        *)
            log_error "Invalid option: $1. Use --help for usage information."
            ;;
    esac
}

# Run the main function
main "$@"