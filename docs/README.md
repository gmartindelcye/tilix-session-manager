# tilix-session-manager

Survives reboots and power failures. Saves Tilix window layout + all tmux sessions automatically; restores everything in one command.

## How it works

Two complementary layers:

| Layer | Tool | What it saves |
|-------|------|---------------|
| **Process persistence** | tmux + tmux-resurrect | Running processes, pane contents, CWDs |
| **Layout restore** | tilix-session script | Tilix tabs/windows mapped to tmux sessions |

tmux-continuum auto-saves every 10 min in the background. The `tilix-session` script ties Tilix layout to tmux session names so everything reopens correctly.

## Quick start

```bash
# Install the script to your PATH
sudo ln -s ~/dev/gmartindelcye/tilix-session-manager/scripts/tilix-session /usr/local/bin/tilix-session

# First save (do this while Tilix + tmux are running)
tilix-session save

# Set up auto-save systemd timer (10-min interval)
tilix-session install

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

## Files

```
~/.tmux.conf                          tmux config (plugins, keybindings, theme)
~/.tmux/plugins/                      TPM plugins
~/.tmux/resurrect/                    tmux-resurrect snapshots (auto-managed)
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
