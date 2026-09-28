#!/usr/bin/env bash
# claude-aliases.sh — Claude Code shell aliases for multiple LLM providers via headroom
# Sourced from ~/.zshrc by install.sh.
# Machine-specific API keys live in config/local.env (gitignored — never committed).
#
# ⚠  MODEL PICKER NOTE
# Claude Code's /model command always shows Anthropic models — it cannot be changed.
# When routing to an alternative provider (DeepSeek, Mistral, etc.) via CLAUDE_BASE_URL,
# the model name Claude Code sends (e.g. claude-sonnet-4-5) goes to the provider's
# OpenAI-compatible API. Whether that provider honours, remaps, or rejects it depends
# on the provider. To target a specific provider model, set the PROVIDER_MODEL env var
# before launching (e.g. PROVIDER_MODEL=mistral-large-latest claude-mistral) — the
# _claude_provider helper passes it as --model to claude if set.

# Load machine-specific API keys
_TS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[[ -f "$_TS_DIR/local.env" ]] && source "$_TS_DIR/local.env"
unset _TS_DIR

# Internal helper: set provider env vars and launch headroom wrap claude.
# Usage: _claude_provider <api_key> <base_url> [extra headroom/claude args...]
_claude_provider() {
    local key="$1" url="$2"
    shift 2
    export CLAUDE_API_KEY="$key" CLAUDE_BASE_URL="$url"
    local model_arg=()
    [[ -n "${PROVIDER_MODEL:-}" ]] && model_arg=(-- --model "$PROVIDER_MODEL")
    headroom wrap claude "${model_arg[@]}" "$@"
}

# ── Default (Anthropic direct, via headroom) ──────────────────────────────────
alias claude-default='unset CLAUDE_API_KEY; unset CLAUDE_BASE_URL; headroom wrap claude'
alias claude-default-continue='unset CLAUDE_API_KEY; unset CLAUDE_BASE_URL; headroom wrap claude -- -c'

# ── Without headroom (bare claude binary) ─────────────────────────────────────
alias claude-bare='unset CLAUDE_API_KEY; unset CLAUDE_BASE_URL; claude'
alias claude-bare-continue='unset CLAUDE_API_KEY; unset CLAUDE_BASE_URL; claude -c'

# ── DeepSeek ─────────────────────────────────────────────────────────────────
alias claude-deepseek='_claude_provider "${DEEPSEEK_API_KEY:-}" "https://api.deepseek.com/v1"'
alias claude-deepseek-continue='_claude_provider "${DEEPSEEK_API_KEY:-}" "https://api.deepseek.com/v1" -- -c'

# ── OpenAI (GPT) ─────────────────────────────────────────────────────────────
alias claude-openai='_claude_provider "${OPENAI_API_KEY:-}" "https://api.openai.com/v1"'
alias claude-openai-continue='_claude_provider "${OPENAI_API_KEY:-}" "https://api.openai.com/v1" -- -c'

# ── Qwen (Alibaba / DashScope) ───────────────────────────────────────────────
alias claude-qwen='_claude_provider "${QWEN_API_KEY:-}" "https://dashscope.aliyuncs.com/compatible-mode/v1"'
alias claude-qwen-continue='_claude_provider "${QWEN_API_KEY:-}" "https://dashscope.aliyuncs.com/compatible-mode/v1" -- -c'

# ── Gemini (Google) ──────────────────────────────────────────────────────────
alias claude-gemini='_claude_provider "${GEMINI_API_KEY:-}" "https://generativelanguage.googleapis.com/v1beta/openai/"'
alias claude-gemini-continue='_claude_provider "${GEMINI_API_KEY:-}" "https://generativelanguage.googleapis.com/v1beta/openai/" -- -c'

# ── Grok (xAI) ───────────────────────────────────────────────────────────────
alias claude-grok='_claude_provider "${GROK_API_KEY:-}" "https://api.x.ai/v1"'
alias claude-grok-continue='_claude_provider "${GROK_API_KEY:-}" "https://api.x.ai/v1" -- -c'

# ── Mistral ───────────────────────────────────────────────────────────────────
alias claude-mistral='_claude_provider "${MISTRAL_API_KEY:-}" "https://api.mistral.ai/v1"'
alias claude-mistral-continue='_claude_provider "${MISTRAL_API_KEY:-}" "https://api.mistral.ai/v1" -- -c'

# ── Custom provider ───────────────────────────────────────────────────────────
# Set CUSTOM_API_KEY and CUSTOM_BASE_URL in local.env, then use these aliases.
alias claude-custom='_claude_provider "${CUSTOM_API_KEY:-}" "${CUSTOM_BASE_URL:-}"'
alias claude-custom-continue='_claude_provider "${CUSTOM_API_KEY:-}" "${CUSTOM_BASE_URL:-}" -- -c'
