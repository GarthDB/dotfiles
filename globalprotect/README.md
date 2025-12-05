# GlobalProtect VPN Automation

This topic integrates the [GlobalProtect VPN automation tools](https://github.com/your-org/macos-globalprotect-bot) into your dotfiles.

## What It Does

- **Adds `~/.local/bin` to PATH**: Enables XDG-compliant tools (GlobalProtect and others)
- **Installs GlobalProtect tools**: Automatically installs the VPN automation scripts
- **Provides convenient aliases**: Quick shortcuts for VPN operations

## Installation

The GlobalProtect tools will be automatically installed when you run:

```bash
cd ~/.dotfiles
script/install
```

Or manually:

```bash
cd ~/.dotfiles/globalprotect
./install.sh
```

## Commands

Once installed, these commands are available:

### Main Commands
- `globalconnect` - Main automation script
- `gc-connect` - Quick connect wrapper (most commonly used)
- `gp-test` - Test suite

### Aliases (from `aliases.zsh`)
- `vpn` / `vpnc` - Quick connect to VPN
- `vpns` - Check VPN status
- `vpnd` - Disconnect from VPN
- `vpnt` - Test VPN connectivity
- `vpnconf` - Edit VPN configuration
- `vpnlogs` - View VPN logs

## Usage Examples

```bash
# Connect to VPN (interactive)
vpn

# Check status
vpns

# Test connectivity
vpnt

# Disconnect
vpnd

# View logs
vpnlogs
```

## Configuration

Configuration is stored in `~/.config/globalprotect-bot/environment.yaml`

Edit it with:
```bash
vpnconf
# or
gc-connect config
```

## Requirements

- The GlobalProtect project must be located at: `~/Projects/macos-globalprotect-bot-main`
- GlobalProtect/GlobalConnect must be installed on your Mac
- macOS (uses macOS-specific automation)

## Sharing Across Computers

This dotfiles integration ensures that when you set up a new computer:

1. Clone your dotfiles repo
2. Run `script/bootstrap`
3. Run `script/install`
4. GlobalProtect tools are automatically available!

Just make sure the GlobalProtect project exists at `~/Projects/macos-globalprotect-bot-main` on each machine.

