# tilix-session-manager

Survives reboots and power failures. Saves Tilix window layout + all tmux sessions automatically; restores everything in one command.

## How it works

Two complementary layers:

| Layer | Tool | What it saves |
|-------|------|---------------|
| **Process persistence** | tmux + tmux-resurrect | Running processes, pane contents, CWDs |
| **Layout restore** | tilix-session script | Tilix tabs/windows mapped to tmux sessions |

tmux-continuum auto-saves every 10 min in the background. The `tilix-session` script ties Tilix layout to tmux session names so everything reopens correctly.

## Dependencies

| Dependency | Required | Installed by | Notes |
|------------|----------|-------------|-------|
| `tmux` | ✅ | `install.sh` via apt | v3.0+ recommended |
| `tilix` | ✅ | manual | `sudo apt install tilix` |
| `git` | ✅ | manual | to clone this repo and TPM |
| `python3` | ✅ | pre-installed on Ubuntu | builds Tilix layout JSON |
| `systemd` (user session) | optional | pre-installed | for auto-save timer |
| `xclip` | optional | `sudo apt install xclip` | clipboard support in tmux copy mode |

Install missing manual deps before running `install.sh`:

```bash
sudo apt install tilix git xclip
```

## Install on a new machine

```bash
git clone git@github.com:gmartindelcye/tilix-session-manager.git ~/dev/gmartindelcye/tilix-session-manager
cd ~/dev/gmartindelcye/tilix-session-manager
./scripts/install.sh
```

That single script:
1. Installs tmux (via apt)
2. Installs TPM + plugins (resurrect, continuum, sensible)
3. Deploys `config/tmux.conf` → `~/.tmux.conf` (backs up any existing one)
4. Symlinks `tilix-session` to `/usr/local/bin`
5. Enables the systemd 10-min auto-save timer

Pass `--no-timer` to skip the systemd timer (e.g. on servers without a user session).

## Quick start (first use)

```bash
# Start a tmux session for your main workspace
tilix-session attach main

# Save current state
tilix-session save

# After a reboot — restore everything
tilix-session restore
```

## Commands

```
tilix-session save       Save current tmux sessions → Tilix layout JSON
tilix-session restore    Restore last saved layout in Tilix
tilix-session status     Show saved sessions and last save time
tilix-session attach     Attach to (or create) the main tmux session
tilix-session install    Install systemd auto-save timer (runs every 10m)
tilix-session uninstall  Remove systemd timer
```

## Daily workflow

Open Tilix and start a tmux session for each project:

```bash
# Instead of bare terminals, always use tmux
tilix-session attach myproject      # creates or reattaches 'myproject' session
tilix-session attach devserver      # another session for a running server
```

When you have the layout you want, save it:

```bash
tilix-session save
```

After reboot:

```bash
tilix-session restore    # reopens Tilix, reattaches all tmux sessions
```

## tmux quick reference

| Key | Action |
|-----|--------|
| `Ctrl-a |` | Split vertical |
| `Ctrl-a -` | Split horizontal |
| `Ctrl-a c` | New window |
| `Ctrl-a h/j/k/l` | Navigate panes |
| `Ctrl-a d` | Detach (session stays alive) |
| `Shift+←/→` | Previous/next window |
| `Ctrl-a r` | Reload tmux config |

Prefix is `Ctrl-a` (not the default `Ctrl-b`).

## tmux-resurrect manual save/restore

tmux-continuum saves automatically, but you can also trigger manually:

- **Save**: `Ctrl-a` then `Ctrl-s`
- **Restore**: `Ctrl-a` then `Ctrl-r`

Saved files are in `~/.tmux/resurrect/`.

## Repo layout

```
tilix-session-manager/
├── config/
│   └── tmux.conf                     source-of-truth tmux config
├── scripts/
│   ├── install.sh                    bootstrap script for new machines
│   └── tilix-session                 save/restore/status CLI
└── docs/
    └── README.md
```

## Runtime files (created on first use)

```
~/.tmux.conf                          deployed by install.sh from config/tmux.conf
~/.tmux/plugins/                      TPM + resurrect + continuum + sensible
~/.tmux/resurrect/                    tmux-resurrect snapshots (auto-managed, ~10 files)
~/.local/share/tilix-session/
  layout.json                         Tilix session file (tabs → tmux sessions)
  tmux-sessions.txt                   Session names at last save
  last-save                           Timestamp of last save
~/.config/systemd/user/
  tilix-session-autosave.service
  tilix-session-autosave.timer
```

## What survives a power failure

| Item | Survives? | Notes |
|------|-----------|-------|
| tmux session names | ✅ | Restored by tmux-resurrect |
| Running processes | ✅ | Restored by tmux-resurrect |
| Pane contents (scrollback) | ✅ | `@resurrect-capture-pane-contents on` |
| Tilix tab layout | ✅ | Restored by `tilix-session restore` |
| Unsaved file edits | ❌ | Save your files |
| Active SSH connections | ❌ | tmux keeps the pane; connection drops |
