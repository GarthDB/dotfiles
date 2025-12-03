#!/bin/sh
#
# Ghostty
#
# Sets up Ghostty configuration

GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
DOTFILES_GHOSTTY="$HOME/.dotfiles/ghostty/config"

# Create config directory if it doesn't exist
if [ ! -d "$GHOSTTY_CONFIG_DIR" ]; then
  mkdir -p "$GHOSTTY_CONFIG_DIR"
  echo "  Created $GHOSTTY_CONFIG_DIR"
fi

# Symlink the config file
if [ -f "$DOTFILES_GHOSTTY" ]; then
  if [ -L "$GHOSTTY_CONFIG_DIR/config" ]; then
    echo "  Ghostty config already linked"
  elif [ -f "$GHOSTTY_CONFIG_DIR/config" ]; then
    echo "  Backing up existing Ghostty config"
    mv "$GHOSTTY_CONFIG_DIR/config" "$GHOSTTY_CONFIG_DIR/config.backup"
    ln -s "$DOTFILES_GHOSTTY" "$GHOSTTY_CONFIG_DIR/config"
    echo "  Linked Ghostty config"
  else
    ln -s "$DOTFILES_GHOSTTY" "$GHOSTTY_CONFIG_DIR/config"
    echo "  Linked Ghostty config"
  fi
fi


