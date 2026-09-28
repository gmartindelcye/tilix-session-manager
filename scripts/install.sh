#!/usr/bin/env bash
# install.sh — bootstrap tilix-session-manager on a fresh machine
# Run once after cloning the repo.
#
# Usage: ./scripts/install.sh [--no-timer]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NO_TIMER=false

for arg in "$@"; do
    [[ "$arg" == "--no-timer" ]] && NO_TIMER=true
done

info()    { echo "  → $*"; }
success() { echo "  ✓ $*"; }
header()  { echo ""; echo "── $* ─────────────────────────────────────"; }

# ─── 1. tmux ────────────────────────────────────────────────────────────────

header "tmux"
if command -v tmux &>/dev/null; then
    success "tmux already installed ($(tmux -V))"
else
    info "Installing tmux..."
    sudo apt-get install -y tmux
    success "tmux installed ($(tmux -V))"
fi

# ─── 2. TPM (Tmux Plugin Manager) ───────────────────────────────────────────

header "TPM"
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    success "TPM already installed"
else
    info "Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    success "TPM cloned"
fi

# ─── 3. tmux config ─────────────────────────────────────────────────────────

header "tmux config"
TMUX_CONF="$HOME/.tmux.conf"
if [[ -f "$TMUX_CONF" ]]; then
    BACKUP="$TMUX_CONF.bak.$(date +%Y%m%d%H%M%S)"
    info "Existing ~/.tmux.conf found — backing up to $BACKUP"
    cp "$TMUX_CONF" "$BACKUP"
fi
cp "$REPO_DIR/config/tmux.conf" "$TMUX_CONF"
success "~/.tmux.conf installed"

# ─── 4. Install TPM plugins ──────────────────────────────────────────────────

header "tmux plugins"
info "Installing plugins via TPM (resurrect + continuum + sensible)..."
tmux new-session -d -s _install 2>/dev/null || true
tmux run-shell "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>&1 | grep -E "Installing|Already|Done" || true
tmux kill-session -t _install 2>/dev/null || true
success "Plugins installed: $(ls ~/.tmux/plugins/ | tr '\n' ' ')"

# ─── 5. tilix-session script ────────────────────────────────────────────────

header "tilix-session script"
SCRIPT_SRC="$REPO_DIR/scripts/tilix-session"
chmod +x "$SCRIPT_SRC"

LINK="/usr/local/bin/tilix-session"
if [[ -L "$LINK" ]] || [[ -f "$LINK" ]]; then
    info "Removing existing $LINK"
    sudo rm -f "$LINK"
fi
sudo ln -s "$SCRIPT_SRC" "$LINK"
success "tilix-session → $LINK"

# ─── 6. Systemd auto-save timer ─────────────────────────────────────────────

header "systemd timer"
if $NO_TIMER; then
    info "Skipped (--no-timer)"
else
    if command -v systemctl &>/dev/null && systemctl --user status &>/dev/null 2>&1; then
        tilix-session install
        success "Auto-save timer enabled (every 10 min)"
    else
        info "systemd user session not available — skipping timer"
        info "You can enable it later with: tilix-session install"
    fi
fi

# ─── Done ───────────────────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════════════"
echo " tilix-session-manager installed successfully"
echo "══════════════════════════════════════════════"
echo ""
echo " Quick start:"
echo "   tilix-session attach main    # start/attach tmux session"
echo "   tilix-session save           # snapshot current state"
echo "   tilix-session restore        # restore after reboot"
echo "   tilix-session status         # check what's saved"
echo ""
echo " tmux prefix: Ctrl-a  (not Ctrl-b)"
echo "   Ctrl-a |   split vertical"
echo "   Ctrl-a -   split horizontal"
echo "   Ctrl-a d   detach (session stays alive)"
echo ""
