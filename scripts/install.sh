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

header "tilix-session commands → ~/.local/bin"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

for script in tilix-session tilix-sessions.sh; do
    src="$REPO_DIR/scripts/$script"
    name="${script%.sh}"          # strip .sh so both become bare commands
    link="$LOCAL_BIN/$name"
    chmod +x "$src"
    ln -sf "$src" "$link"
    success "$name → $link"
done

# Ensure ~/.local/bin is in PATH (add to .zshrc if missing)
if ! echo "$PATH" | grep -q "$LOCAL_BIN"; then
    if ! grep -qF "$LOCAL_BIN" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"  # tilix-session-manager' >> "$HOME/.zshrc"
        info "Added ~/.local/bin to PATH in ~/.zshrc (restart shell or: source ~/.zshrc)"
    fi
fi

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

# ─── 7. Claude/headroom aliases ─────────────────────────────────────────────

header "Claude aliases"
ALIASES_SRC="$REPO_DIR/config/claude-aliases.sh"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE="source \"$ALIASES_SRC\"  # tilix-session-manager"

if grep -qF "$ALIASES_SRC" "$ZSHRC" 2>/dev/null; then
    success "Claude aliases already sourced in ~/.zshrc"
else
    echo "" >> "$ZSHRC"
    echo "$SOURCE_LINE" >> "$ZSHRC"
    success "Added claude aliases to ~/.zshrc"
fi

LOCAL_ENV="$REPO_DIR/config/local.env"
if [[ ! -f "$LOCAL_ENV" ]]; then
    cp "$REPO_DIR/config/local.env.template" "$LOCAL_ENV"
    info "Created config/local.env — add your DEEPSEEK_API_KEY if needed"
fi

# ─── Done ───────────────────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════════════"
echo " tilix-session-manager installed successfully"
echo "══════════════════════════════════════════════"
echo ""
echo " Quick start:"
echo "   tilix-session pane-save      # snapshot Tilix pane directories"
echo "   tilix-session pane-restore   # interactively rebuild layout"
echo "   tilix-session save           # snapshot tmux + pane state"
echo "   tilix-session restore        # restore tmux layout in Tilix"
echo "   tilix-session status         # check what's saved"
echo ""
echo " tmux prefix: Ctrl-a  (not Ctrl-b)"
echo "   Ctrl-a |   split vertical"
echo "   Ctrl-a -   split horizontal"
echo "   Ctrl-a d   detach (session stays alive)"
echo ""
