#!/bin/bash

# ======================================================================
# tune_macos_performance.sh - macOS Performance Optimization Script
# ======================================================================
#
# Description:
#   This script is designed to optimize macOS systems specifically for AI/ML
#   development workloads. It applies various system-level optimizations
#   that can significantly improve performance for compute-intensive tasks.
#
# Features:
#   - UI/UX optimizations (reduces animations and visual effects)
#   - CPU and memory management tweaks
#   - Network and storage optimizations
#   - GPU configuration for ML workloads
#   - Python environment optimizations
#   - System maintenance recommendations
#
# Requirements:
#   - macOS 10.15 (Catalina) or later
#   - Administrator privileges (for system-level changes)
#   - Homebrew (for some optimizations)
#
# Usage:
#   ./tune_macos_performance.sh [--apply|--backup|--restore|--help]
#
# Note:
#   - Always create a backup before applying changes
#   - Some changes may require a restart to take effect
#   - Review all changes before applying in production environments
#
# Author: Nicholas G
# Version: 1.0.0
# Last Updated: 2025-05-26
# ======================================================================

# Function to optimize CPU management (disabling some services)
optimize_cpu_management() {
    log_info "Optimizing CPU management by disabling some unnecessary services..."
    log_warn "Disabling system services can have unintended side effects. Proceed with caution."

    # Disable Time Machine local snapshots (if not using Time Machine regularly)
    # Local snapshots can consume significant CPU and disk I/O
    log_info "Disabling Time Machine local snapshots..."
    sudo tmutil disablelocal &>/dev/null
    
    # Disable App Nap for all applications
    # App Nap can throttle background applications to save power
    log_info "Disabling App Nap system-wide..."
    defaults write NSGlobalDomain NSAppSleepDisabled -bool YES
    
    # Disable automatic termination of inactive apps
    log_info "Preventing system from terminating inactive apps..."
    defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
    
    # ===========================================================================
    # Timer Coalescing Optimization
    # ===========================================================================
    # Purpose: Disables timer coalescing to reduce latency for time-sensitive tasks
    #
    # What it does:
    # - Timer coalescing is a power-saving feature that groups multiple timer events
    #   together to reduce CPU wake-ups, improving battery life
    # - Setting kern.timer.coalescing_enabled=0 disables this feature, causing
    #   timer events to be processed immediately when they occur
    #
    # When to enable this:
    # - Running latency-sensitive applications (audio production, real-time systems)
    # - AI/ML workloads requiring precise timing
    # - Development environments where maximum responsiveness is preferred
    #
    # Benefits:
    # - Reduces input/output latency
    # - Improves application responsiveness
    # - Provides more consistent performance for time-sensitive operations
    # - Can improve performance for applications that rely on precise timing
    #
    # Drawbacks:
    # - Increases power consumption (reduces battery life on laptops)
    # - May generate more heat under load
    # - Default macOS behavior is optimized for balanced performance/battery life
    #
    # Default value: 1 (enabled)
    # Recommended: 0 for performance-critical workstations, 1 for laptops on battery
    # ===========================================================================
    log_info "Disabling timer coalescing for better performance (kern.timer.coalescing_enabled=0)..."
    sudo sysctl -w kern.timer.coalescing_enabled=0
    
    log_success "CPU management optimizations applied."
    log_info "Note: Some changes may require a restart to take full effect."

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
    echo "Usage: $0 [OPTION]"
    echo "Tune macOS for AI/ML performance."
    echo ""
    echo "Options:"
    echo "  --apply    Apply all performance optimizations."
    echo "  --backup   Backup current macOS defaults settings."
    echo "  --restore  Restore macOS defaults settings from the latest backup."
    echo "  --help     Display this help message."
    echo ""
    echo "Note: Applying optimizations will prompt for confirmation before making changes."
    exit 1
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

    # Check if the key exists before attempting to read
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

    # UI Animations
    backup_defaults_setting com.apple.dock autohide-time-modifier -float
    backup_defaults_setting com.apple.dock autohide-delay -float
    backup_defaults_setting com.apple.dock expose-animation-duration -float
    backup_defaults_setting com.apple.dock springboard-show-duration -float
    backup_defaults_setting com.apple.dock springboard-hide-duration -float
    backup_defaults_setting com.apple.dock springboard-page-duration -float
    backup_defaults_setting NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool
    backup_defaults_setting com.apple.Mail DisableReplyAnimations -bool
    backup_defaults_setting com.apple.Mail DisableSendAnimations -bool
    backup_defaults_setting NSGlobalDomain NSWindowResizeTime -float
    backup_defaults_setting com.apple.finder DisableAllAnimations -bool
    backup_defaults_setting -g QLPanelAnimationDuration -float
    backup_defaults_setting com.apple.dock mineffect -string
    backup_defaults_setting NSGlobalDomain NSScrollAnimationEnabled -bool
    backup_defaults_setting com.apple.universalaccess reduceTransparency -bool

    # DNS Caching
    backup_defaults_setting /Library/Preferences/com.apple.mDNSResponder.plist CacheTime -int
    backup_defaults_setting /Library/Preferences/com.apple.mDNSResponder.plist CacheEntries -int

    log_success "Backup completed. Settings saved to ${BACKUP_FILE}"
}

# Function to restore defaults settings from a backup file
restore_all_defaults() {
    local latest_backup_file=$(ls -t "${BACKUP_DIR}"/defaults_backup_*.plist 2>/dev/null | head -n 1)

    if [[ -z "${latest_backup_file}" ]]; then
        log_error "No backup file found in ${BACKUP_DIR}. Please run with --backup first."
    fi

    log_info "Restoring macOS defaults settings from ${latest_backup_file}..."

    while IFS= read -r line; do
        local domain=$(echo "${line}" | awk '{print $1}')
        local key=$(echo "${line}" | awk '{print $2}')
        local type=$(echo "${line}" | awk '{print $3}')
        local value=$(echo "${line}" | cut -d' ' -f4-) # Get everything after the 3rd field

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

# --- Optimization Functions ---

# Function to optimize UI animations
optimize_animations() {
    log_info "Optimizing UI animations..."
    # Commands to disable animations, adapted from toggle_animations.sh --off
    sudo defaults write com.apple.dock autohide-time-modifier -float 0
    sudo defaults write com.apple.dock autohide-delay -float 0
    sudo defaults write com.apple.dock expose-animation-duration -float 0
    sudo defaults write com.apple.dock springboard-show-duration -float 0
    sudo defaults write com.apple.dock springboard-hide-duration -float 0
    sudo defaults write com.apple.dock springboard-page-duration -float 0
    sudo defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    sudo defaults write com.apple.Mail DisableReplyAnimations -bool true
    sudo defaults write com.apple.Mail DisableSendAnimations -bool true
    sudo defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    sudo defaults write com.apple.finder DisableAllAnimations -bool true
    sudo defaults write -g QLPanelAnimationDuration -float 0
    sudo defaults write com.apple.dock mineffect -string "scale"
    sudo defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false
    sudo defaults write com.apple.universalaccess reduceTransparency -bool true
    sudo defaults write com.apple.dock expose-animation-duration -float 0.1 # Speed up Mission Control animations

    log_info "Restarting Dock and Finder to apply animation changes..."
    killall Dock &>/dev/null
    killall Finder &>/dev/null
    log_success "UI animations optimized."
    log_warn "Some changes like 'reduceTransparency' might require a logout/login to take full effect."
}

# Function to optimize CPU management (disabling some services)
optimize_cpu_management() {
    log_info "Optimizing CPU management by disabling some unnecessary services..."
    log_warn "Disabling system services can have unintended side effects. Proceed with caution."

    # Disable Time Machine local snapshots (if not using Time Machine regularly)
    log_info "Disabling Time Machine local snapshots..."
    sudo tmutil disablelocal &>/dev/null
    
    log_success "Time Machine local snapshots disabled."
    log_success "CPU management optimizations applied."
}

# Function to optimize memory management
optimize_memory_management() {
    log_info "Optimizing memory management..."

    # Clear inactive memory and purge disk caches
    # This is particularly useful before running memory-intensive tasks
    log_info "Purging inactive memory and disk caches..."
    sudo purge &>/dev/null
    log_success "Inactive memory and disk caches purged."

    # Memory compression settings
    log_info "Configuring memory compression settings..."
    
    # Display current memory pressure and compression stats
    log_info "Current memory pressure status:"
    memory_pressure -q
    
    # Optimize swap usage
    log_info "Configuring swap usage for better performance..."
    sudo sysctl -w vm.compressor_mode=4  # More aggressive compression
    
    # Increase shared memory limits (useful for Python multiprocessing)
    log_info "Increasing shared memory limits..."
    sudo sysctl -w kern.sysv.shmmax=4194304000  # 4GB
    sudo sysctl -w kern.sysv.shmall=1024000
    
    # Disable memory pressure notifications that can cause app throttling
    log_info "Disabling memory pressure notifications..."
    sudo sysctl -w kern.memorystatus_use_pressure=0
    
    # Documentation about memory management
    log_info "Memory Management Notes:"
    log_info "  - macOS uses a sophisticated memory management system with compression"
    log_info "  - The 'purge' command clears disk caches and inactive memory"
    log_info "  - Memory compression helps prevent swapping to disk"
    log_info "  - Monitor memory pressure using Activity Monitor or 'memory_pressure' command"
    
    log_success "Memory management optimized."
    log_warn "Some memory optimizations may be reset after system restart."

# Function to optimize storage
optimize_storage() {
    log_info "Optimizing storage..."

    # Disable Spotlight indexing for specific development directories
    log_warn "Spotlight indexing for specific development directories needs to be configured manually. Use 'sudo mdutil -i off /path/to/your/dev/folder' for your large project directories."

    # Clear temporary files and logs
    log_info "Clearing temporary files and logs..."
    sudo rm -rf /private/var/log/* &>/dev/null
    sudo rm -rf /private/var/tmp/* &>/dev/null
    sudo rm -rf ~/Library/Caches/* &>/dev/null
    sudo rm -rf ~/Library/Logs/* &>/dev/null
    log_success "Temporary files and logs cleared."

    log_success "Storage optimized."
}

# Function to optimize network settings
optimize_network() {
    log_info "Optimizing network settings..."

    # Optimize DNS caching (increase cache time and size)
    log_info "Adjusting DNS cache settings for longer retention and larger cache..."
    # Increase DNS cache time (e.g., 86400 seconds = 24 hours)
    sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist CacheTime -int 86400 &>/dev/null
    # Increase DNS cache size (e.g., 10000 entries)
    sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist CacheEntries -int 10000 &>/dev/null
    log_success "DNS cache settings adjusted."
    log_info "Flushing DNS cache to apply new settings..."
    sudo dscacheutil -flushcache &>/dev/null
    sudo killall -HUP mDNSResponder &>/dev/null
    log_success "DNS cache flushed and new settings applied."

    # Adjust TCP/IP buffer sizes (more aggressive settings for high throughput)
    log_info "Adjusting TCP/IP buffer sizes..."
    sudo sysctl -w net.inet.tcp.recvspace=1048576 &>/dev/null
    sudo sysctl -w net.inet.tcp.sendspace=1048576 &>/dev/null
    sudo sysctl -w net.inet.tcp.max_recv_window=1048576 &>/dev/null
    sudo sysctl -w net.inet.tcp.max_send_window=1048576 &>/dev/null
    log_success "TCP/IP buffer sizes adjusted."
    log_warn "Network buffer tuning can sometimes lead to instability or reduced performance on certain networks. Monitor network performance after applying."

    log_success "Network settings optimized."
}

# Function for GPU configuration and monitoring for ML workloads
optimize_gpu_ml() {
    log_info "Optimizing GPU configuration for ML workloads..."
    log_warn "Direct GPU configuration on Apple Silicon is largely managed by the OS and ML frameworks (e.g., Metal Performance Shaders, Core ML)."
    log_info "Ensure your ML frameworks are configured to utilize Apple's Metal Performance Shaders (MPS) for optimal GPU performance."
    log_info "For example, in PyTorch, ensure you are using 'mps' device if available: 'torch.backends.mps.is_available()'."

    log_info "Recommended tools for GPU monitoring:"
    log_info "  - Activity Monitor: Check 'GPU History' under the 'Window' menu."
    log_info "  - powermetrics: Run 'sudo powermetrics --samplers gpu_power,cpu_power -i 1000' in Terminal for detailed power usage."
    log_info "  - Xcode Instruments: For in-depth analysis of Metal performance."
    log_success "GPU optimization recommendations provided."
}

# Function for Python environment performance optimizations
optimize_python_env() {
    log_info "Optimizing Python environment performance..."
    log_info "  - Clearing pip cache: 'pip cache purge'"
    pip cache purge &>/dev/null
    log_info "  - Clearing conda cache: 'conda clean --all' (if conda is installed)"
    if command -v conda &>/dev/null; then
        conda clean --all &>/dev/null
    fi
    log_info "  - Setting OMP_NUM_THREADS environment variable for CPU-bound libraries (e.g., NumPy, SciPy, scikit-learn):"
    log_info "    Export OMP_NUM_THREADS to the number of physical CPU cores for optimal performance."
    log_info "    Example: 'export OMP_NUM_THREADS=$(sysctl -n hw.physicalcpu)'"
    log_success "Python environment optimizations applied/recommended."
}

# Function to optimize swap file settings for large model training
optimize_swap_settings() {
    log_info "Optimizing swap file settings for large model training..."
    log_warn "Modifying swap settings can impact system stability. Proceed with extreme caution."
    log_warn "These changes are generally not recommended unless you have specific memory pressure issues during large model training."

    # Increase vm.swapusage (more aggressive swapping, but can lead to slower performance if overused)
    # This is counter-intuitive for "performance" but can prevent OOM errors for very large models.
    # Default is usually 0 (auto-managed). Setting a high value might force more swapping.
    # A better approach is to ensure enough RAM or use memory-efficient techniques.
    # For now, I will set a higher value for vm.swapfile_max_size and vm.swapfile_min_size
    # to allow for larger swap files if needed, without forcing more swapping.
    # These values are in bytes. 1GB = 1073741824 bytes.
    log_info "Setting vm.swapfile_max_size and vm.swapfile_min_size to allow for larger swap files..."
    sudo sysctl -w vm.swapfile_max_size=10737418240 &>/dev/null # 10GB
    sudo sysctl -w vm.swapfile_min_size=1073741824 &>/dev/null  # 1GB
    log_success "Swap file size limits adjusted."
    log_warn "These changes allow for larger swap files but do not force more swapping. Actual swap usage depends on memory pressure."
    log_warn "Consider increasing physical RAM or using memory-efficient ML techniques before relying heavily on swap."

    log_success "Swap file settings optimized/recommended."
}

# Function to configure resource allocation for common ML tasks
configure_ml_resource_allocation() {
    log_info "Configuring resource allocation for common ML tasks..."
    log_info "  - Using 'nice' and 'renice' to adjust process priority:"
    log_info "    'nice' allows you to start a process with a modified priority."
    log_info "    'renice' allows you to change the priority of a running process."
    log_info "    Lower 'nice' values (e.g., -20) mean higher priority, higher values (e.g., 19) mean lower priority."
    log_info "    Example: 'nice -n -10 python your_ml_script.py'"
    log_info "    Example: 'sudo renice -n -10 -p <PID_of_your_ml_process>'"
    log_warn "  - Be cautious when setting high priorities, as it can make your system unresponsive."
    log_success "ML resource allocation recommendations provided."
}

# Function for developer tooling recommendations (existing, will be updated)
developer_tooling_recommendations() {
    log_info "Providing developer tooling recommendations..."

    log_info "Python Environment Optimization:"
    log_info "  - Always use virtual environments (e.g., conda, venv) for your Python projects to manage dependencies and avoid conflicts."
    log_info "  - Consider optimizing pip/conda cache settings for faster package installations. (e.g., 'pip cache purge' or 'conda clean --all')"

    log_info "Docker Optimization:"
    log_info "  - Configure Docker Desktop resource limits (CPU, memory, disk) to match your system's capabilities and workload requirements."
    log_info "  - Optimize Docker daemon settings for performance, such as using a faster storage driver if applicable."

    log_info "VS Code Optimization:"
    log_info "  - Install extensions like 'Resource Monitor' or 'Performance Monitor' to keep an eye on VS Code's resource usage."
    log_info "  - Adjust VS Code settings for large file handling and resource usage (e.g., 'files.watcherExclude', 'search.exclude')."

    log_success "Developer tooling recommendations provided."
}

# Function for system maintenance and cleanup recommendations (existing)
system_maintenance_and_cleanup() {
    log_info "Providing system maintenance and cleanup recommendations..."

    log_info "Automated Cleanup:"
    log_info "  - Consider scheduling regular system cleanup tasks (e.g., using cron jobs or launchd) to remove old logs, caches, and temporary files."
    log_info "  - Tools like 'OnyX' or 'CleanMyMac X' can assist with automated cleanup, but use with caution."

    log_info "Disk Space Monitoring:"
    log_info "  - Regularly monitor disk space, especially in critical development partitions or for large datasets. Low disk space can severely impact performance."
    log_info "  - Use 'df -h' or 'Disk Utility' to check disk usage."

    log_success "System maintenance and cleanup recommendations provided."
}

# --- Main Script Execution ---
main() {
    if [[ "$#" -eq 0 || "$1" == "--help" ]]; then
        usage
    fi

    case "$1" in
        --apply)
            log_info "Attempting to apply macOS performance optimizations."
            if confirm_action "This script will make system-level changes. Do you want to proceed?"; then
                backup_all_defaults # Backup before applying changes
                optimize_animations
                optimize_cpu_management
                optimize_memory_management
                optimize_storage
                optimize_network
                optimize_gpu_ml
                optimize_python_env
                optimize_swap_settings
                configure_ml_resource_allocation
                developer_tooling_recommendations # Keep this for general recommendations
                system_maintenance_and_cleanup # Keep this for general recommendations
                log_success "macOS performance tuning script completed."
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
            log_error "Invalid option: $1"
            usage
            ;;
    esac
}

# Run the main function
main "$@"