#!/usr/bin/env bash
#
# GlobalProtect VPN Automation
# Installs the GlobalProtect automation tools

set -e

cd "$(dirname "$0")"

GP_PROJECT_DIR="$HOME/Projects/macos-globalprotect-bot-main"

# Check if the GlobalProtect project exists
if [ ! -d "$GP_PROJECT_DIR" ]; then
  echo "  GlobalProtect project not found at $GP_PROJECT_DIR"
  echo "  Skipping GlobalProtect installation"
  exit 0
fi

echo "› Installing GlobalProtect automation tools"

# Run the installation script
cd "$GP_PROJECT_DIR"

# Check if already installed
if [ -d "$HOME/.config/globalprotect-bot" ] && [ -f "$HOME/.local/bin/globalconnect" ]; then
  echo "  GlobalProtect automation tools already installed"
  echo "  Binaries: $HOME/.local/bin/globalconnect, gc-connect, gp-test"
  echo "  Config: $HOME/.config/globalprotect-bot/"
  exit 0
fi

# Run installation in non-interactive mode if possible
if [ -f "install.sh" ]; then
  # The installer will handle PATH configuration
  # We answer 'n' to automatic PATH setup since we handle it via dotfiles
  printf "n\n" | ./install.sh || {
    echo "  Installation may require manual intervention"
    echo "  Run: cd $GP_PROJECT_DIR && ./install.sh"
    exit 1
  }
else
  echo "  install.sh not found in $GP_PROJECT_DIR"
  exit 1
fi

echo "✓ GlobalProtect automation tools installed"

