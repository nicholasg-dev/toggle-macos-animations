#!/bin/bash

# Script to toggle macOS animations

# Function to display usage
usage() {
    echo "Usage: $0 [--on|--off]"
    exit 1
}

# Check if an argument is provided
if [ -z "$1" ]; then
    usage
fi

# Process the argument
case "$1" in
    --on)
        echo "Enabling animations..."
        # Commands from enableanimations.sh
        defaults delete com.apple.dock autohide-time-modifier
        defaults delete com.apple.dock autohide-delay
        defaults delete com.apple.dock expose-animation-duration
        defaults delete com.apple.dock springboard-show-duration
        defaults delete com.apple.dock springboard-hide-duration
        defaults delete com.apple.dock springboard-page-duration
        defaults delete NSGlobalDomain NSAutomaticWindowAnimationsEnabled
        defaults delete com.apple.Mail DisableReplyAnimations
        defaults delete com.apple.Mail DisableSendAnimations
        defaults delete NSGlobalDomain NSWindowResizeTime
        defaults delete com.apple.finder DisableAllAnimations
        defaults delete -g QLPanelAnimationDuration
        defaults delete com.apple.dock mineffect # Restore default minimize animation
        defaults delete NSGlobalDomain NSScrollAnimationEnabled # Enable scroll animations
        defaults delete com.apple.universalaccess reduceTransparency # Disable reduce transparency
        # Note: enableanimations.sh has 'defaults delete com.apple.dock expose-animation-duration' twice.
        # Assuming it's intentional or a slight oversight, keeping one instance here.
        echo "Animations enabled."
        echo "Note: Some changes like 'reduceTransparency' might require a logout/login to take full effect."
        ;;
    --off)
        echo "Disabling animations..."
        # Commands from disableanimations.sh
        defaults write com.apple.dock autohide-time-modifier -float 0
        defaults write com.apple.dock autohide-delay -float 0
        defaults write com.apple.dock expose-animation-duration -float 0 # This will be overridden by the later 0.1 if not handled
        defaults write com.apple.dock springboard-show-duration -float 0
        defaults write com.apple.dock springboard-hide-duration -float 0
        defaults write com.apple.dock springboard-page-duration -float 0
        defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
        defaults write com.apple.Mail DisableReplyAnimations -bool true
        defaults write com.apple.Mail DisableSendAnimations -bool true
        defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
        defaults write com.apple.finder DisableAllAnimations -bool true
        defaults write -g QLPanelAnimationDuration -float 0
        defaults write com.apple.dock mineffect -string "scale" # Set minimize animation to scale
        defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false # Disable scroll animations
        defaults write com.apple.universalaccess reduceTransparency -bool true # Enable reduce transparency for performance
        # defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false # Duplicate, already set above
        defaults write com.apple.dock expose-animation-duration -float 0.1 # Speed up Mission Control animations
        # defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false # Duplicate
        # defaults write NSGlobalDomain NSWindowResizeTime -float 0.001 # Duplicate
        echo "Animations disabled."
        echo "Note: Some changes like 'reduceTransparency' might require a logout/login to take full effect."
        ;;
    *)
        usage
        ;;
esac

# Restart affected applications to apply changes
echo "Restarting Dock and Finder to apply changes..."
killall Dock
killall Finder

echo "Done."