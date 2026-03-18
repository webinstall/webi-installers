---
name: opencode
description: Terminal-based AI coding assistant with multi-provider LLM support, file editing, shell access, and plugin system. Use when the user wants AI pair programming in the terminal.
homepage: https://github.com/anomalyco/opencode
---

# OpenCode

Terminal-based AI coding assistant that connects to multiple LLM providers (Anthropic, OpenAI, Google, local Ollama) with an interactive TUI for writing, reviewing, and refactoring code.

## When to Use

- User wants AI pair programming directly in the terminal
- User needs to switch between multiple LLM providers mid-session
- User wants full tool use (file editing, shell commands, grep, read)
- User prefers terminal UIs over web-based interfaces
- User wants plugin-based multi-agent orchestration (oh-my-opencode)
- User wants local-first AI coding with Ollama (no API costs)

## Installation

```sh
curl https://webi.sh/opencode | sh
source ~/.config/envman/PATH.env
```

## Quick Start

1. **Set API key** (Anthropic, OpenAI, or Google):
   ```sh
   export ANTHROPIC_API_KEY="sk-ant-..."
   # or
   export OPENAI_API_KEY="sk-..."
   ```

2. **Launch in project directory**:
   ```sh
   cd ~/your-project
   opencode
   ```

3. **Start coding** — opencode gives you a TUI where you can chat, edit files, run commands, and navigate your codebase.

## Configuration

### Multi-Provider Setup

Edit `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "anthropic": {},
    "openai": {},
    "google": {}
  },
  "model": {
    "big": "anthropic/claude-sonnet-4-5-20250514",
    "small": "anthropic/claude-haiku-4-5-20250514"
  }
}
```

### Local Models with Ollama (Optional)

For offline AI coding with no API calls:

```sh
# Install Ollama separately
curl https://webi.sh/ollama | sh

# Start server and pull model
ollama serve &
ollama pull qwen2.5-coder:14b
```

Configure opencode to use local model:

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

## Plugin System (oh-my-opencode)

Adds specialized agents, model routing, and skill-based delegation:

```sh
cd ~/.config/opencode
npm install oh-my-opencode
```

Configure agents in `~/.config/opencode/oh-my-opencode.json`:

```json
{
  "agents": {
    "oracle": {
      "description": "Read-only high-IQ consultant for architecture",
      "model": "anthropic/claude-sonnet-4-5-20250514",
      "tools": ["Read", "Grep", "Glob", "WebFetch"]
    },
    "reviewer": {
      "description": "Code review specialist",
      "model": "anthropic/claude-sonnet-4-5-20250514",
      "tools": ["Read", "Grep", "Bash"]
    }
  }
}
```

## Key Features

| Feature | Description |
|---------|-------------|
| **Multi-Provider** | Switch between Anthropic, OpenAI, Google, Ollama mid-session |
| **Full Tool Access** | Read/write files, execute shell commands, search codebase |
| **Plugin System** | Extend with custom agents and workflows |
| **Terminal Native** | Runs in any terminal with full keyboard navigation |
| **Context-Aware** | Maintains conversation context across file edits |

## Common Workflows

### Code Review
```sh
opencode
# In TUI: "Review the changes in src/auth.ts and suggest improvements"
```

### Implement Feature
```sh
opencode
# In TUI: "Add user authentication with JWT tokens"
# OpenCode will read files, write code, and execute tests
```

### Debug Issue
```sh
opencode
# In TUI: "Why is the API returning 500 errors?"
# OpenCode will read logs, check code, and suggest fixes
```

### Refactor
```sh
opencode
# In TUI: "Refactor the user service to use async/await instead of promises"
```

## Integration with Other Tools

### With Ollama (Local Models)
Requires `ollama` to be running:
```sh
ollama serve &  # Keep running in background
opencode        # Will connect to local Ollama
```

### With Git
OpenCode is git-aware and can:
- Read diffs
- Suggest commit messages
- Review changes before commit
- Create branches

### With Testing Frameworks
OpenCode can run tests directly:
```sh
opencode
# In TUI: "Run the test suite and fix any failures"
```

## Files Created

```text
~/.config/envman/PATH.env           # PATH configuration
~/.local/bin/opencode               # Symlink to versioned binary
~/.local/opt/opencode-VERSION/      # Installed binary
~/.config/opencode/opencode.json    # Configuration
~/.config/opencode/oh-my-opencode.json  # Plugin config (if installed)
```

## Key Bindings

| Key | Action |
|-----|--------|
| `Enter` | Send message |
| `Ctrl+E` | Open editor for multi-line input |
| `Ctrl+C` | Cancel current operation |
| `Ctrl+L` | Clear screen |
| `/` | Slash commands |

## Comparison with Alternatives

| Tool | OpenCode | Cursor | GitHub Copilot |
|------|----------|--------|----------------|
| **Interface** | Terminal TUI | VS Code fork | IDE extension |
| **Providers** | Multi (Anthropic, OpenAI, Google, Ollama) | OpenAI only | GitHub's models |
| **Local Models** | ✅ Via Ollama | ❌ | ❌ |
| **Plugins** | ✅ oh-my-opencode | Limited | Limited |
| **Shell Access** | ✅ Full | ✅ Terminal | ❌ |
| **Offline** | ✅ With Ollama | ❌ | ❌ |

## Best Practices

1. **Start with cloud LLMs** — Test with Anthropic/OpenAI before switching to local models
2. **Use plugins for complex workflows** — oh-my-opencode adds multi-agent coordination
3. **Configure model tiers** — Use "big" model for complex tasks, "small" for quick edits
4. **Keep Ollama running** — If using local models, keep `ollama serve` in background
5. **Git integration** — Run opencode from git repo root for best context awareness

## Troubleshooting

**OpenCode won't start:**
```sh
# Check if binary is in PATH
which opencode

# Verify configuration
cat ~/.config/opencode/opencode.json
```

**API key not working:**
```sh
# Verify environment variable is set
echo $ANTHROPIC_API_KEY

# Make sure to export, not just set
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Ollama connection failed:**
```sh
# Check if Ollama is running
curl http://localhost:11434/api/version

# Start Ollama if needed
ollama serve &
```

## Resources

- GitHub: https://github.com/anomalyco/opencode
- Plugin System: https://github.com/code-yeongyu/oh-my-opencode
- Model Options: https://opencode.ai/models
- Configuration Schema: https://opencode.ai/config.json

## Related Webi Installers

- `ollama` — Local LLM server for offline AI coding
- `node` — Required for installing plugins (oh-my-opencode)
- `git` — Version control integration
