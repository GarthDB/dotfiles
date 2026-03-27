#!/usr/bin/env bash
# Claude Code config installer

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_SRC="$DOTFILES_ROOT/claude"
CLAUDE_DIR="$HOME/.claude"

link_file() {
  local src=$1 dst=$2
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] already linked: $dst\n"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "${dst}.backup"
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] backed up: $dst -> ${dst}.backup\n"
  fi
  ln -s "$src" "$dst"
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] linked $src -> $dst\n"
}

mkdir -p "$CLAUDE_DIR"

link_file "$CLAUDE_SRC/settings.json" "$CLAUDE_DIR/settings.json"
link_file "$CLAUDE_SRC/CLAUDE.md"     "$HOME/CLAUDE.md"
link_file "$CLAUDE_SRC/plugins"       "$CLAUDE_DIR/plugins"
