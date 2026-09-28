#!/usr/bin/env bash
# claude-aliases.sh — Claude Code shell aliases for multiple LLM providers via headroom
# Sourced from ~/.zshrc by install.sh.
# Machine-specific API keys live in config/local.env (gitignored — never committed).

# Load machine-specific API keys
_TS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[[ -f "$_TS_DIR/local.env" ]] && source "$_TS_DIR/local.env"
unset _TS_DIR

# ── Default (Anthropic direct, no proxy key) ─────────────────────────────────
alias claude-default='unset CLAUDE_API_KEY; unset CLAUDE_BASE_URL; headroom wrap claude'
alias claude-default-continue='unset CLAUDE_API_KEY; unset CLAUDE_BASE_URL; headroom wrap claude -- -c'

# ── Without headroom (direct claude binary) ───────────────────────────────────
alias claude-bare='unset CLAUDE_API_KEY; unset CLAUDE_BASE_URL; claude'
alias claude-bare-continue='unset CLAUDE_API_KEY; unset CLAUDE_BASE_URL; claude -c'

# ── DeepSeek ─────────────────────────────────────────────────────────────────
alias claude-deepseek='export CLAUDE_API_KEY="${DEEPSEEK_API_KEY:-}" CLAUDE_BASE_URL="https://api.deepseek.com/v1"; headroom wrap claude'
alias claude-deepseek-continue='export CLAUDE_API_KEY="${DEEPSEEK_API_KEY:-}" CLAUDE_BASE_URL="https://api.deepseek.com/v1"; headroom wrap claude -- -c'

# ── OpenAI (GPT) ─────────────────────────────────────────────────────────────
alias claude-openai='export CLAUDE_API_KEY="${OPENAI_API_KEY:-}" CLAUDE_BASE_URL="https://api.openai.com/v1"; headroom wrap claude'
alias claude-openai-continue='export CLAUDE_API_KEY="${OPENAI_API_KEY:-}" CLAUDE_BASE_URL="https://api.openai.com/v1"; headroom wrap claude -- -c'

# ── Qwen (Alibaba / DashScope) ───────────────────────────────────────────────
alias claude-qwen='export CLAUDE_API_KEY="${QWEN_API_KEY:-}" CLAUDE_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"; headroom wrap claude'
alias claude-qwen-continue='export CLAUDE_API_KEY="${QWEN_API_KEY:-}" CLAUDE_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"; headroom wrap claude -- -c'

# ── Gemini (Google) ──────────────────────────────────────────────────────────
alias claude-gemini='export CLAUDE_API_KEY="${GEMINI_API_KEY:-}" CLAUDE_BASE_URL="https://generativelanguage.googleapis.com/v1beta/openai/"; headroom wrap claude'
alias claude-gemini-continue='export CLAUDE_API_KEY="${GEMINI_API_KEY:-}" CLAUDE_BASE_URL="https://generativelanguage.googleapis.com/v1beta/openai/"; headroom wrap claude -- -c'

# ── Grok (xAI) ───────────────────────────────────────────────────────────────
alias claude-grok='export CLAUDE_API_KEY="${GROK_API_KEY:-}" CLAUDE_BASE_URL="https://api.x.ai/v1"; headroom wrap claude'
alias claude-grok-continue='export CLAUDE_API_KEY="${GROK_API_KEY:-}" CLAUDE_BASE_URL="https://api.x.ai/v1"; headroom wrap claude -- -c'

# ── Mistral ───────────────────────────────────────────────────────────────────
alias claude-mistral='export CLAUDE_API_KEY="${MISTRAL_API_KEY:-}" CLAUDE_BASE_URL="https://api.mistral.ai/v1"; headroom wrap claude'
alias claude-mistral-continue='export CLAUDE_API_KEY="${MISTRAL_API_KEY:-}" CLAUDE_BASE_URL="https://api.mistral.ai/v1"; headroom wrap claude -- -c'

# ── Custom provider ───────────────────────────────────────────────────────────
# Set CUSTOM_API_KEY and CUSTOM_BASE_URL in local.env, then use these aliases.
alias claude-custom='export CLAUDE_API_KEY="${CUSTOM_API_KEY:-}" CLAUDE_BASE_URL="${CUSTOM_BASE_URL:-}"; headroom wrap claude'
alias claude-custom-continue='export CLAUDE_API_KEY="${CUSTOM_API_KEY:-}" CLAUDE_BASE_URL="${CUSTOM_BASE_URL:-}"; headroom wrap claude -- -c'
