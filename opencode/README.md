---
title: opencode
homepage: https://github.com/anomalyco/opencode
tagline: |
  opencode: A terminal-based AI coding agent with multi-provider LLM support.
---

To update or switch versions, run `webi opencode@stable` (or `@v1.2`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/opencode
~/.local/opt/opencode-VERSION/bin/opencode
~/.config/opencode/opencode.json
```

## Cheat Sheet

> `opencode` is an AI coding agent that runs in the terminal. It connects to LLM
> providers (Anthropic, OpenAI, Google, or local models via Ollama) and gives
> you an interactive TUI with full tool use — file editing, shell commands, and
> codebase navigation.

### How to Get Started

Set an API key and launch in your project directory:

```sh
export ANTHROPIC_API_KEY="sk-ant-..."
cd ~/your-project
opencode
```

opencode starts a TUI where you can chat, edit files, run commands, and navigate
your codebase.

### How to Configure Providers

Add providers to `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "anthropic": {},
    "openai": {}
  },
  "model": {
    "big": "anthropic/claude-sonnet-4-5-20250514",
    "small": "anthropic/claude-haiku-4-5-20250514"
  }
}
```

Anthropic reads `ANTHROPIC_API_KEY`, OpenAI reads `OPENAI_API_KEY`.

### How to Use Plugins

opencode supports plugins for extended workflows.
[oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) adds
multi-agent orchestration, model routing, and specialized skills — the entire
plugin system fits in a single config line:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["oh-my-opencode@latest"],
  "provider": {
    "anthropic": {}
  }
}
```

That's it. One plugin, your providers, done. The plugin handles agent
definitions, skill loading, and model routing automatically.

### How to Use with Local Models

Install [ollama](../ollama/) (also available via webi), then configure opencode:

```sh
webi ollama
ollama serve &
ollama pull qwen2.5-coder:14b
```

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      },
      "models": {
        "qwen2.5-coder:14b": {
          "name": "Qwen 2.5 Coder 14B (local)"
        }
      }
    }
  }
}
```

### Useful Key Bindings

| Key      | Action                           |
| -------- | -------------------------------- |
| `Enter`  | Send message                     |
| `Ctrl+E` | Open editor for multi-line input |
| `Ctrl+C` | Cancel current operation         |
| `Ctrl+L` | Clear screen                     |
| `/`      | Slash commands                   |
