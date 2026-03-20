---
name: opencode
description:
  Terminal-based AI coding agent with multi-provider LLM support, file editing,
  shell access, and plugin system. Use when the user wants AI pair programming
  in the terminal.
homepage: https://github.com/anomalyco/opencode
---

# OpenCode

Terminal-based AI coding agent that connects to multiple LLM providers
(Anthropic, OpenAI, Google, local Ollama) with an interactive TUI for writing,
reviewing, and refactoring code.

## When to Use

- User wants AI pair programming directly in the terminal
- User needs full tool use (file editing, shell commands, grep, read)
- User wants plugin-based multi-agent orchestration (oh-my-opencode)
- User wants local-first AI coding with Ollama (no API costs)

## Installation

```sh
curl https://webi.sh/opencode | sh
source ~/.config/envman/PATH.env
```

## Quick Start

1. **Set API key**:

   ```sh
   export ANTHROPIC_API_KEY="sk-ant-..."
   ```

2. **Launch in project directory**:

   ```sh
   cd ~/your-project
   opencode
   ```

## Configuration

Edit `~/.config/opencode/opencode.json`:

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

### With oh-my-opencode Plugin

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["oh-my-opencode@latest"],
  "provider": {
    "anthropic": {}
  }
}
```

### Local Models with Ollama

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

## Key Bindings

| Key      | Action                           |
| -------- | -------------------------------- |
| `Enter`  | Send message                     |
| `Ctrl+E` | Open editor for multi-line input |
| `Ctrl+C` | Cancel current operation         |
| `Ctrl+L` | Clear screen                     |
| `/`      | Slash commands                   |

## Files Created

```text
~/.config/envman/PATH.env
~/.local/bin/opencode
~/.local/opt/opencode-VERSION/bin/opencode
~/.config/opencode/opencode.json
```

## Related Webi Installers

- `ollama` — Local LLM server for offline AI coding
- `node` — Required for installing plugins (oh-my-opencode)
