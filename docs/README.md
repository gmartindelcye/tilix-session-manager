# tilix-session-manager

Survives reboots and power failures. Saves Tilix window layout + all tmux sessions automatically; restores everything in one command.

## How it works

Three complementary layers:

| Layer | Tool | What it saves |
|-------|------|---------------|
| **Process persistence** | tmux + tmux-resurrect | Running processes, pane contents, CWDs |
| **Layout restore** | tilix-session script | Tilix tabs/windows mapped to tmux sessions |
| **AI session restore** | tilix-session + headroom | Claude Code conversations resumed in the right pane |

tmux-continuum auto-saves every 10 min in the background. The `tilix-session` script ties Tilix layout to tmux session names so everything reopens correctly. If any panes were running Claude Code via `headroom`, they are automatically resumed in continue mode after restore.

## Dependencies

| Dependency | Required | Installed by | Notes |
|------------|----------|-------------|-------|
| `tmux` | ✅ | `install.sh` via apt | v3.0+ recommended |
| `tilix` | ✅ | manual | `sudo apt install tilix` |
| `git` | ✅ | manual | to clone this repo and TPM |
| `python3` | ✅ | pre-installed on Ubuntu | builds Tilix layout JSON |
| `systemd` (user session) | optional | pre-installed | for auto-save timer |
| `xclip` | optional | `sudo apt install xclip` | clipboard support in tmux copy mode |
| `headroom` | optional | `pip install headroom-ai` | required for Claude session restore |

Install missing manual deps before running `install.sh`:

```bash
sudo apt install tilix git xclip
```

## Install on a new machine

```bash
git clone git@github.com:gmartindelcye/tilix-session-manager.git ~/dev/gmartindelcye/tilix-session-manager
cd ~/dev/gmartindelcye/tilix-session-manager
cp config/local.env.template config/local.env   # add DEEPSEEK_API_KEY if using DeepSeek
./scripts/install.sh
```

That single script:
1. Installs tmux (via apt)
2. Installs TPM + plugins (resurrect, continuum, sensible)
3. Deploys `config/tmux.conf` → `~/.tmux.conf` (backs up any existing one)
4. Symlinks `tilix-session` to `/usr/local/bin`
5. Enables the systemd 10-min auto-save timer
6. Sources `config/claude-aliases.sh` from `~/.zshrc` (Claude + headroom aliases)

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
│   ├── tmux.conf                     source-of-truth tmux config
│   ├── claude-aliases.sh             portable Claude/headroom shell aliases
│   └── local.env.template            copy → local.env, add API keys (gitignored)
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
| Claude Code conversations | ✅ | History on disk; `tilix-session restore` resumes via headroom |
| Unsaved file edits | ❌ | Save your files |
| Active SSH connections | ❌ | tmux keeps the pane; connection drops |

## Claude Code + headroom

`tilix-session` tracks which panes are running Claude Code — whether via [headroom](https://headroom.ai) or the bare `claude` binary — and resumes them automatically on restore.

**Aliases installed by `install.sh`** (defined in `config/claude-aliases.sh`):

| Alias | Provider | Requires |
|-------|----------|---------|
| `claude-default` / `claude-default-continue` | Anthropic (direct via headroom) | — |
| `claude-bare` / `claude-bare-continue` | Anthropic (no headroom) | — |
| `claude-deepseek` / `claude-deepseek-continue` | DeepSeek | `DEEPSEEK_API_KEY` |
| `claude-openai` / `claude-openai-continue` | OpenAI / GPT | `OPENAI_API_KEY` |
| `claude-qwen` / `claude-qwen-continue` | Qwen (Alibaba) | `QWEN_API_KEY` |
| `claude-gemini` / `claude-gemini-continue` | Gemini (Google) | `GEMINI_API_KEY` |
| `claude-grok` / `claude-grok-continue` | Grok (xAI) | `GROK_API_KEY` |
| `claude-mistral` / `claude-mistral-continue` | Mistral | `MISTRAL_API_KEY` |
| `claude-custom` / `claude-custom-continue` | Any OpenAI-compatible endpoint | `CUSTOM_API_KEY` + `CUSTOM_BASE_URL` |

All provider aliases follow the same pattern: set `CLAUDE_API_KEY` + `CLAUDE_BASE_URL`, then call `headroom wrap claude`. The continue variants append `-- -c`.

**After a reboot**, `tilix-session restore` automatically sends the appropriate resume command to each saved pane:
- headroom panes → `headroom wrap claude -- -c`
- bare claude panes → `claude -c`

Sessions resume in the correct project directory with conversation history intact. If you were using a provider other than the default (e.g. DeepSeek), re-run its continue alias (`claude-deepseek-continue`) to reactivate the API key in that pane.

**Machine-specific config** (`config/local.env`, gitignored — copy from `local.env.template`):

```bash
DEEPSEEK_API_KEY=...
OPENAI_API_KEY=...
QWEN_API_KEY=...
GEMINI_API_KEY=...
```
