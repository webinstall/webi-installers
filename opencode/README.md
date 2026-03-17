---
title: opencode
homepage: https://github.com/opencode-ai/opencode
tagline: |
  opencode: AI-powered coding assistant for your terminal.
---

To update or switch versions, run `webi opencode@stable` (or `@v0.0.55`, etc).

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

> `opencode` is a terminal-based AI coding assistant. It connects to LLM
> providers (Anthropic, OpenAI, Google, local models via Ollama) and gives you
> an interactive TUI for writing, reviewing, and refactoring code — with full
> tool use, file editing, and shell access.

### How to Get Started

1. Set an API key for your preferred provider:

   ```sh
   export ANTHROPIC_API_KEY="sk-ant-..."
   # or
   export OPENAI_API_KEY="sk-..."
   ```

2. Launch opencode in your project directory:

   ```sh
   cd ~/your-project
   opencode
   ```

   opencode starts a TUI where you can chat, edit files, run commands, and
   navigate your codebase — all from the terminal.

### How to Use with Ollama (Local Models)

Both `opencode` and [`ollama`](../ollama/) are available via webi, so you can
install a fully local AI coding setup with no API keys:

```sh
curl https://webi.sh/ollama | sh
curl https://webi.sh/opencode | sh
source ~/.config/envman/PATH.env
```

1. Start the `ollama` server and pull a model:

   ```sh
   ollama serve &
   ollama pull qwen2.5-coder:14b
   ```

2. Create a minimal config at `~/.config/opencode/opencode.json`:

   ```json
   {
     "$schema": "https://opencode.ai/config.json",
     "provider": {
       "ollama": {
         "models": {
           "qwen-coder": {
             "id": "qwen2.5-coder:14b",
             "name": "Qwen 2.5 Coder 14B"
           }
         }
       }
     },
     "model": {
       "big": "ollama/qwen-coder",
       "small": "ollama/qwen-coder"
     }
   }
   ```

3. Launch opencode:

   ```sh
   opencode
   ```

   It will connect to your local Ollama instance — no external API calls, fully
   offline.

### How to Use the Plugin System (oh-my-opencode)

opencode supports plugins for multi-agent orchestration, custom tools, and
extended workflows.
[oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) is a plugin
that adds specialized agents, model routing, and skill-based delegation:

1. Install the plugin:

   ```sh
   cd ~/.config/opencode
   npm install oh-my-opencode
   ```

2. Add it to `~/.config/opencode/opencode.json`:

   ```json
   {
     "$schema": "https://opencode.ai/config.json",
     "plugin": ["oh-my-opencode"]
   }
   ```

3. Configure agents and model routing in
   `~/.config/opencode/oh-my-opencode.json`. A minimal example:

   ```json
   {
     "agents": {
       "oracle": {
         "description": "Read-only high-IQ consultant for architecture and debugging",
         "model": "anthropic/claude-sonnet-4-5-20250514",
         "tools": ["Read", "Grep", "Glob", "WebFetch"]
       }
     }
   }
   ```

   See the
   [oh-my-opencode README](https://github.com/code-yeongyu/oh-my-opencode) for
   the full agent and category configuration reference.

### How to Configure Providers

opencode supports multiple LLM providers simultaneously. Add them to
`opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "anthropic": {},
    "openai": {},
    "ollama": {
      "models": {
        "local-model": {
          "id": "qwen2.5-coder:14b",
          "name": "Local Qwen Coder"
        }
      }
    }
  },
  "model": {
    "big": "anthropic/claude-sonnet-4-5-20250514",
    "small": "anthropic/claude-haiku-4-5-20250514"
  }
}
```

Anthropic and OpenAI providers read from `ANTHROPIC_API_KEY` and
`OPENAI_API_KEY` environment variables respectively.

### Useful Key Bindings

| Key      | Action                           |
| -------- | -------------------------------- |
| `Enter`  | Send message                     |
| `Ctrl+E` | Open editor for multi-line input |
| `Ctrl+C` | Cancel current operation         |
| `Ctrl+L` | Clear screen                     |
| `/`      | Slash commands                   |
