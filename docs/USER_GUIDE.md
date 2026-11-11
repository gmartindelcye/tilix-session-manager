# tilix-session-manager — User Guide

## What this solves

When Tilix closes or the machine reboots, your terminal layout is gone. Every open directory, running process, split pane. You start from scratch.

This tool saves the state and brings it back. Two independent workflows — use either or both:

- **Native pane workflow** — saves Tilix pane directories directly; interactive restore lets you pick layouts and groupings. No tmux required.
- **tmux workflow** — full process persistence across reboots; running servers, SSH connections, and Claude Code sessions survive power failures.

---

## Install

```bash
sudo apt install tilix git xclip xdotool
git clone git@github.com:gmartindelcye/tilix-session-manager.git ~/dev/gmartindelcye/tilix-session-manager
cd ~/dev/gmartindelcye/tilix-session-manager
cp config/local.env.template config/local.env
./scripts/install.sh
```

`install.sh` links commands to `~/.local/bin` (no sudo), sources Claude aliases from `~/.zshrc`, and optionally enables the auto-save systemd timer.

---

## Native Tilix pane workflow

This is the simpler workflow — no tmux needed.

### Save before closing / rebooting

```bash
tilix-session pane-save
```

Snapshots the working directory of every active Tilix pane to `~/.local/share/tilix-session/panes.json`. The auto-save timer does this automatically every 10 minutes when Tilix is running.

You can also inspect what's currently running:

```bash
tilix-sessions            # human-readable table
tilix-sessions --json     # JSON output
tilix-sessions --watch    # live refresh every 2s
```

### Restore after reboot

```bash
tilix-session pane-restore
```

Interactive prompt walks you through rebuilding your layout:

```
Saved panes:
  [1] /home/gmartin/dev/Phalkon-Dev/phalkon-compliance
  [2] /home/gmartin/dev/Phalkon-Dev/phalkon-infra
  [3] /home/gmartin/dev/Phalkon-Dev/vigilum-screening
  [4] /home/gmartin/dev/Phalkon-Dev/phalkon-tools
  [5] /home/gmartin/Documents/Vigilum
  [6] /home/gmartin

How many tabs? 2

Tab 1:
  v = vertical split     (2 panes: left | right)
  t = tall-left          (3 panes: big left | top-right / bottom-right)
  Layout [v/t]: t
  Pane numbers (3 needed, e.g. 1 2 3): 1 2 3

Tab 2:
  Layout [v/t]: t
  Pane numbers (3 needed, e.g. 1 2 3): 4 5 6

Command for project panes [claude-default]:
```

Tilix opens with the specified layout. Project panes `cd` to their directory and launch the command automatically.

### Layout types

**`v` — vertical split (2 panes)**
```
┌──────────┬──────────┐
│    A     │    B     │
└──────────┴──────────┘
```

**`t` — tall-left (3 panes)**
```
┌──────────┬──────────┐
│          │    B     │
│    A     ├──────────┤
│          │    C     │
└──────────┴──────────┘
```

---

## tmux workflow

Use this when you need running processes to survive reboots (dev servers, SSH, long builds).

### Concepts

**Tilix** is the GUI window you see. When closed, it's gone.

**tmux** is a background process that holds your shell sessions. Even when Tilix closes, tmux keeps running. When you reopen Tilix, you reconnect and everything is still there.

### Daily usage

```bash
# Start or reattach a named session
tilix-session attach main
tilix-session attach phalkon-api
tilix-session attach devserver

# Save current layout and session state
tilix-session save

# After reboot — restore everything
tilix-session restore
```

### tmux keyboard reference

Prefix: `Ctrl-a` (hold Ctrl, press a, release, then press next key)

**Panes**

| Keys | Action |
|------|--------|
| `Ctrl-a \|` | Split vertical |
| `Ctrl-a -` | Split horizontal |
| `Ctrl-a h/j/k/l` | Navigate panes |
| `Ctrl-a z` | Zoom pane (toggle fullscreen) |
| `Ctrl-a x` | Close pane |

**Windows & Sessions**

| Keys | Action |
|------|--------|
| `Ctrl-a c` | New window |
| `Shift+←/→` | Previous / next window |
| `Ctrl-a d` | Detach (session stays running) |
| `Ctrl-a s` | Show all sessions |

**Copy mode**

| Keys | Action |
|------|--------|
| `Ctrl-a Enter` | Enter copy mode |
| `v` | Start selection |
| `y` | Copy to clipboard |
| `/` | Search |
| `q` | Exit |

**Save / restore (tmux-resurrect)**

| Keys | Action |
|------|--------|
| `Ctrl-a Ctrl-s` | Save manually |
| `Ctrl-a Ctrl-r` | Restore manually |

---

## Claude Code

### Aliases

```bash
claude-default          # Anthropic direct, via headroom (recommended)
claude-bare             # Anthropic direct, no headroom
claude-deepseek         # DeepSeek  (needs DEEPSEEK_API_KEY in config/local.env)
claude-openai           # OpenAI / GPT  (OPENAI_API_KEY)
claude-qwen             # Qwen / Alibaba  (QWEN_API_KEY)
claude-gemini           # Gemini  (GEMINI_API_KEY)
claude-grok             # Grok / xAI  (GROK_API_KEY)
claude-mistral          # Mistral  (MISTRAL_API_KEY)
claude-custom           # Any OpenAI-compatible endpoint
```

Each has a `-continue` variant (e.g. `claude-default-continue`) that resumes the last conversation with `-c`.

To target a specific provider model:

```bash
PROVIDER_MODEL=deepseek-chat claude-deepseek
PROVIDER_MODEL=grok-3 claude-grok
```

### Session persistence

When using `pane-restore`, project panes launch `claude-default` automatically. After a reboot:

```bash
tilix-session pane-restore    # panes open in correct directories with claude-default running
```

When using the tmux workflow, `tilix-session restore` sends `headroom wrap claude -- -c` to any pane that had Claude running at last save.

---

## Auto-save

The systemd timer runs `tilix-session save` every 10 minutes automatically. `save` includes `pane-save` when Tilix is running. tmux-continuum saves tmux state independently every 10 minutes.

```bash
tilix-session status        # check timer and last save
tilix-session install       # (re-)enable timer
tilix-session uninstall     # disable timer
```

To change the interval, edit `~/.config/systemd/user/tilix-session-autosave.timer`:

```ini
[Timer]
OnUnitActiveSec=5min
```

Then: `systemctl --user daemon-reload && systemctl --user restart tilix-session-autosave.timer`

---

## Troubleshooting

**`pane-restore` splits land in the wrong tab**
Increase the sleep delays. Edit the generated setup scripts in `/tmp/tilix-restore-*/` before they exit, or raise the `sleep 0.8` values in the `cmd_pane_restore` function in `scripts/tilix-session`.

**`tilix-session restore` opens Tilix but panes show errors**
Trigger tmux-resurrect manually: inside tmux press `Ctrl-a Ctrl-r`. Then reattach: `tilix-session attach main`.

**Auto-save timer not running**
```bash
tilix-session status
tilix-session install
```

**Claude didn't resume after restore**
Claude wasn't running when you last ran `tilix-session save`. Run `tilix-session save` while Claude is open, then restore. For provider-specific sessions, re-run the `-continue` alias manually after restore to activate the API key.

**Plugins not installed**
```bash
~/.tmux/plugins/tpm/bin/install_plugins
# or inside tmux: Ctrl-a I
```
