# tilix-session-manager

Saves and restores Tilix terminal sessions across reboots and power failures. Combines native Tilix pane snapshots with tmux session persistence and automatic Claude Code resumption.

## How it works

| Layer | Tool | What it saves |
|-------|------|---------------|
| **Pane directories** | `tilix-session pane-save` | Active Tilix pane working directories |
| **Process persistence** | tmux + tmux-resurrect | Running processes, pane contents, CWDs |
| **Tilix layout** | `tilix-session save/restore` | Tilix tabs mapped to tmux sessions |
| **AI sessions** | headroom | Claude Code conversations resumed automatically |

## Install

```bash
sudo apt install tilix git xclip
git clone git@github.com:gmartindelcye/tilix-session-manager.git ~/dev/gmartindelcye/tilix-session-manager
cd ~/dev/gmartindelcye/tilix-session-manager
cp config/local.env.template config/local.env   # add API keys
./scripts/install.sh
```

No sudo required for the install script. Commands are linked to `~/.local/bin`.

Pass `--no-timer` to skip the systemd auto-save timer.

## Commands

```
tilix-session pane-save      Snapshot active Tilix pane directories
tilix-session pane-restore   Interactively rebuild Tilix layout from snapshot
tilix-session save           Save tmux sessions + Tilix layout + pane state
tilix-session restore        Restore tmux layout in Tilix + resume Claude sessions
tilix-session status         Show saved sessions and last save time
tilix-session attach         Attach to (or create) a named tmux session
tilix-session install        Install systemd auto-save timer (every 10 min)
tilix-session uninstall      Remove systemd timer

tilix-sessions               List active Tilix panes (TTY, directory, running command)
tilix-sessions --json        JSON output
tilix-sessions --watch       Live refresh every 2s
```

## Quick start — native Tilix pane workflow

```bash
# Save current pane layout before closing / rebooting
tilix-session pane-save

# Restore interactively after reboot
tilix-session pane-restore
```

`pane-restore` shows your saved directories, asks how many tabs, the layout per tab, and which directories go where. Supported layouts:

- **`v`** — 2-pane vertical split (left | right)
- **`t`** — tall-left: 1 big left pane + 2 stacked right panes

## Quick start — tmux workflow

```bash
tilix-session attach main      # start or reattach tmux session
tilix-session save             # snapshot layout + processes
tilix-session restore          # restore after reboot
```

## Auto-save

The systemd timer runs `tilix-session save` every 10 minutes automatically (includes pane-save when Tilix is running). tmux-continuum also saves tmux state every 10 minutes independently.

## Claude Code aliases

Installed from `config/claude-aliases.sh` via `install.sh`:

| Alias | Provider |
|-------|----------|
| `claude-default` | Anthropic direct (via headroom) |
| `claude-bare` | Anthropic direct (no headroom) |
| `claude-deepseek` | DeepSeek |
| `claude-openai` | OpenAI / GPT |
| `claude-qwen` | Qwen (Alibaba) |
| `claude-gemini` | Gemini (Google) |
| `claude-grok` | Grok (xAI) |
| `claude-mistral` | Mistral |
| `claude-custom` | Any OpenAI-compatible endpoint |

Each alias has a `-continue` variant (e.g. `claude-default-continue`) that resumes the last conversation.

## Dependencies

| Dependency | Required | Notes |
|------------|----------|-------|
| `tilix` | ✅ | `sudo apt install tilix` |
| `python3` | ✅ | pre-installed on Ubuntu |
| `xdotool` | ✅ | required for pane-restore tab creation |
| `tmux` | optional | for tmux workflow; installed by `install.sh` |
| `systemd` | optional | for auto-save timer |
| `xclip` | optional | clipboard in tmux copy mode |
| `headroom` | optional | for Claude session auto-resume |

## Repo layout

```
tilix-session-manager/
├── config/
│   ├── tmux.conf               source-of-truth tmux config
│   ├── claude-aliases.sh       Claude/headroom shell aliases
│   └── local.env.template      copy → local.env, add API keys (gitignored)
├── scripts/
│   ├── install.sh              bootstrap for new machines
│   ├── tilix-session           main CLI (save/restore/pane-save/pane-restore/...)
│   └── tilix-sessions.sh       pane scanner utility
└── docs/
    ├── README.md
    └── USER_GUIDE.md
```

## Runtime files

```
~/.local/bin/
  tilix-session               symlink → scripts/tilix-session
  tilix-sessions              symlink → scripts/tilix-sessions.sh
~/.local/share/tilix-session/
  panes.json                  saved Tilix pane directories
  layout.json                 Tilix session file (tabs → tmux sessions)
  tmux-sessions.txt           session names at last save
  last-save                   timestamp of last save
~/.config/systemd/user/
  tilix-session-autosave.service
  tilix-session-autosave.timer
```
