# tilix-session-manager — User Guide

## What this solves

Normally when Tilix closes, reboots happen, or power dies — everything is gone. Every terminal window, running server, open directory. You start from scratch.

This tool keeps three things alive:

- **Your running processes** (dev servers, watchers, SSH connections) — via tmux, which keeps sessions alive in the background even when the terminal window closes.
- **Your Tilix layout** (tabs, windows, which session is open where) — via a saved JSON snapshot that reopens everything exactly as you left it.
- **Your Claude Code sessions** — if you run Claude via headroom, `tilix-session restore` resumes your conversations in the right pane automatically.

After a reboot: one command and you're back.

---

## Concepts (read this once)

### tmux vs Tilix

**Tilix** is the window you see — tabs, split panes, colors. It's a GUI app. When you close it or reboot, it's gone.

**tmux** is a process that runs in the background, invisible to the GUI. It holds your shell sessions. Even if Tilix closes, tmux keeps running. When you reopen Tilix, you reconnect to tmux and everything is still there.

Think of tmux as a persistent container, and Tilix as the window you use to look inside it.

### Sessions, windows, panes

```
tmux
└── session "main"
    ├── window 1 "editor"
    │   ├── pane (nvim)
    │   └── pane (git log)
    └── window 2 "server"
        └── pane (npm run dev)
└── session "devops"
    └── window 1
        └── pane (ssh gmartin@10.100.0.76)
```

- **Session** — a named workspace. You can have one per project.
- **Window** — like a tab inside a session.
- **Pane** — a split inside a window.

### What survives what

| Event | tmux session | Tilix layout | Running processes | Claude session |
|-------|-------------|--------------|-------------------|----------------|
| Close Tilix window | ✅ intact | ❌ gone | ✅ intact | ✅ intact |
| Reboot / power failure | depends* | ❌ gone | depends* | ✅ on disk |
| `tilix-session restore` | ✅ restored | ✅ restored | ✅ restored | ✅ resumed |

*tmux-resurrect saves session state every 10 minutes automatically. After reboot it restores sessions on tmux start. Claude conversation history lives in `~/.claude/projects/` and survives reboots; `tilix-session restore` resumes headroom in the right pane.

---

## First-time setup

### 1. Install

```bash
sudo apt install tilix git xclip
git clone git@github.com:gmartindelcye/tilix-session-manager.git ~/dev/gmartindelcye/tilix-session-manager
cd ~/dev/gmartindelcye/tilix-session-manager
./scripts/install.sh
```

### 2. Open Tilix and start your first tmux session

```bash
tilix-session attach main
```

You're now inside a tmux session called `main`. The status bar at the bottom confirms it — you'll see `main` on the left in dark navy.

### 3. Save the state

```bash
tilix-session save
```

### 4. Verify auto-save is running

```bash
tilix-session status
```

You should see the timer active and the last save timestamp.

---

## Daily usage

### Starting work

Instead of opening a bare Tilix terminal, attach to a tmux session:

```bash
tilix-session attach main          # general workspace
tilix-session attach phalkon       # project-specific
tilix-session attach devserver     # long-running processes
```

If the session doesn't exist yet, it's created automatically.

### Opening multiple projects at once

Open Tilix, then in each tab:

```
Tab 1: tilix-session attach main
Tab 2: tilix-session attach phalkon-api
Tab 3: tilix-session attach devserver
```

Save the layout:

```bash
tilix-session save
```

Next time you open Tilix after a reboot, `tilix-session restore` brings all three tabs back, each already attached to its tmux session.

### Detaching without closing

Press `Ctrl-a d` to detach from tmux. Tilix stays open but the session keeps running in the background. You can reconnect any time with `tilix-session attach <name>`.

### Closing Tilix safely

Just close it. Your tmux sessions keep running in the background. Nothing is lost.

---

## After a reboot or power failure

```bash
tilix-session restore
```

This:
1. Triggers tmux-resurrect to restore all sessions and their processes
2. Opens Tilix with your saved layout — each tab reconnected to its session
3. Waits 2 seconds, then resumes any Claude Code sessions that were open — running `headroom wrap claude -- -c` in each pane so your conversations pick up where they left off

If Tilix is already open, you can also restore manually:

```bash
# Restore tmux sessions first
Ctrl-a  then  Ctrl-r

# Then reattach
tilix-session attach main
```

---

## tmux keyboard reference

All shortcuts use the prefix `Ctrl-a` (hold Ctrl, press a, release both, then press the next key).

### Panes

| Keys | Action |
|------|--------|
| `Ctrl-a \|` | Split pane vertically (left/right) |
| `Ctrl-a -` | Split pane horizontally (top/bottom) |
| `Ctrl-a h` | Move to pane on the left |
| `Ctrl-a j` | Move to pane below |
| `Ctrl-a k` | Move to pane above |
| `Ctrl-a l` | Move to pane on the right |
| `Ctrl-a x` | Close current pane |
| `Ctrl-a z` | Zoom pane to full screen (toggle) |

### Windows

| Keys | Action |
|------|--------|
| `Ctrl-a c` | New window (keeps current directory) |
| `Shift+←` | Previous window |
| `Shift+→` | Next window |
| `Ctrl-a ,` | Rename current window |
| `Ctrl-a w` | Show window list |
| `Ctrl-a &` | Close window |

### Sessions

| Keys | Action |
|------|--------|
| `Ctrl-a d` | Detach (session stays running) |
| `Ctrl-a s` | Show all sessions |
| `Ctrl-a $` | Rename current session |

### Copy mode (scrollback, search, copy)

| Keys | Action |
|------|--------|
| `Ctrl-a Enter` | Enter copy mode |
| `q` | Exit copy mode |
| `↑ / ↓` or `k / j` | Scroll |
| `Ctrl-u` | Scroll up half page |
| `Ctrl-d` | Scroll down half page |
| `/` | Search forward |
| `?` | Search backward |
| `v` | Start selection |
| `y` | Copy selection to clipboard |

### Config

| Keys | Action |
|------|--------|
| `Ctrl-a r` | Reload `~/.tmux.conf` |

### Save / restore (tmux-resurrect)

| Keys | Action |
|------|--------|
| `Ctrl-a Ctrl-s` | Save sessions manually |
| `Ctrl-a Ctrl-r` | Restore sessions manually |

---

## tilix-session command reference

```
tilix-session save
```
Saves all active tmux session names and builds a Tilix layout JSON that maps each session to a tab. Also triggers tmux-resurrect to snapshot process state, and records which panes have Claude Code running via headroom.

```
tilix-session restore
```
Restores tmux sessions via tmux-resurrect, opens Tilix with the saved layout, then automatically resumes any saved Claude Code sessions in their panes.

```
tilix-session status
```
Shows last save time, active tmux sessions, recent resurrect files, saved Claude sessions, and auto-save timer state.

```
tilix-session attach [name]
```
Attaches to a named tmux session. Creates it if it doesn't exist. Defaults to `main`.

```
tilix-session install
```
Installs and enables the systemd user timer that runs `tilix-session save` every 10 minutes automatically.

```
tilix-session uninstall
```
Disables and removes the auto-save timer.

---

## Common scenarios

### Running Claude Code in a project session

Start Claude inside a tmux session so it persists and restores. Pick the alias that matches your provider:

```bash
tilix-session attach myproject
cd ~/dev/myproject

claude-default       # Anthropic direct, via headroom
claude-bare          # Anthropic direct, no headroom
claude-deepseek      # DeepSeek  (DEEPSEEK_API_KEY in config/local.env)
claude-openai        # OpenAI / GPT  (OPENAI_API_KEY)
claude-qwen          # Qwen / Alibaba  (QWEN_API_KEY)
claude-gemini        # Gemini  (GEMINI_API_KEY)
claude-grok          # Grok / xAI  (GROK_API_KEY)
claude-mistral       # Mistral  (MISTRAL_API_KEY)
claude-custom        # any OpenAI-compatible endpoint  (CUSTOM_API_KEY + CUSTOM_BASE_URL)
```

Save the layout:

```bash
tilix-session save   # records which panes have Claude running and how (headroom or direct)
```

After a reboot:

```bash
tilix-session restore   # Tilix reopens; Claude resumes automatically in each saved pane
```

For provider-specific sessions (DeepSeek, OpenAI, etc.), `tilix-session restore` sends `headroom wrap claude -- -c` which uses whichever API key is currently in the shell. On a fresh boot the shell is clean, so re-run the provider alias (`claude-deepseek-continue`, `claude-openai-continue`, etc.) if you need a specific backend active.

### Running a dev server that survives closing Tilix

```bash
tilix-session attach devserver
npm run dev                         # or any long-running process
# Ctrl-a d  →  detach
```

The server keeps running. Tomorrow:

```bash
tilix-session attach devserver      # reconnect — server still running, logs still there
```

### SSH to remote machine that persists

```bash
tilix-session attach remote
ssh gmartin@10.100.0.76

# Inside the remote: also use tmux
tmux new-session -A -s work
```

If the SSH connection drops (network issue, laptop sleep), reconnect:

```bash
tilix-session attach remote
ssh gmartin@10.100.0.76
tmux attach-session -t work        # pick up exactly where you left off on the remote
```

### Working on multiple projects in parallel

```bash
tilix-session attach phalkon-core
tilix-session attach phalkon-ui
tilix-session attach phalkon-api
tilix-session save
```

Each project has its own isolated session. Switch between them from the Tilix tabs or with `Ctrl-a s`.

### Manual save before a risky operation

```bash
tilix-session save        # snapshot now
# do the risky thing
tilix-session save        # snapshot after, if it worked
```

---

## Customizing tmux config

The config lives in the repo at `config/tmux.conf` and is deployed to `~/.tmux.conf`. Edit it there, then:

```bash
# Apply changes without restarting tmux
Ctrl-a r

# Or from the command line
tmux source ~/.tmux.conf
```

To update the repo copy after changes:

```bash
cp ~/.tmux.conf ~/dev/gmartindelcye/tilix-session-manager/config/tmux.conf
cd ~/dev/gmartindelcye/tilix-session-manager
git add config/tmux.conf && git commit -m "config: update tmux.conf"
```

---

## Troubleshooting

### `tilix-session restore` opens Tilix but panes show "command not found"

tmux-resurrect may not have restored yet. Manually trigger it inside tmux:

```bash
Ctrl-a  Ctrl-r
```

Wait 2–3 seconds, then check sessions:

```bash
tmux list-sessions
```

### Sessions are gone after reboot

tmux-continuum restores automatically when tmux starts. If tmux isn't started yet:

```bash
tmux new-session -d -s init
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
```

Or just run `tilix-session restore` which handles this automatically.

### Auto-save timer not running

```bash
tilix-session status           # check timer state
tilix-session install          # re-enable if missing
systemctl --user status tilix-session-autosave.timer   # detailed status
```

### tmux prefix not working

Confirm your config is loaded:

```bash
tmux show-options -g prefix    # should show: prefix C-a
tmux source ~/.tmux.conf       # reload if needed
```

### Claude didn't resume after restore

Check what was saved:

```bash
tilix-session status         # look for the "claude sessions" section
```

If the list is empty, Claude wasn't running when you last ran `tilix-session save`. Save while Claude is open, then restore.

If the pane target is stale (session renamed or window layout changed), the `tmux send-keys` silently fails. Run `claude-default-continue` manually in the correct pane.

For provider-specific sessions (DeepSeek, OpenAI, Qwen, Gemini, etc.): `tilix-session restore` resumes with `headroom wrap claude -- -c`, which uses whichever API key is in the current shell environment. On a fresh boot the shell is clean — re-run the provider alias (`claude-deepseek-continue`, `claude-openai-continue`, etc.) manually to activate that backend.

### Plugins not installed

```bash
~/.tmux/plugins/tpm/bin/install_plugins
```

Or inside tmux: `Ctrl-a I` (capital I) to install plugins via TPM.

---

## Auto-save schedule

The systemd timer runs `tilix-session save` every 10 minutes. tmux-continuum also saves tmux session state every 10 minutes independently. In practice, you lose at most ~10 minutes of layout changes after a power failure — running processes and shell history are restored from the most recent resurrect snapshot.

To change the interval, edit `~/.config/systemd/user/tilix-session-autosave.timer`:

```ini
[Timer]
OnUnitActiveSec=5min    # change to any interval
```

Then reload:

```bash
systemctl --user daemon-reload
systemctl --user restart tilix-session-autosave.timer
```
