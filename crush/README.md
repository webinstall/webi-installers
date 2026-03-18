---
title: crush
homepage: https://github.com/charmbracelet/crush
tagline: |
  crush: Your new coding bestie, now available in your favourite terminal.
---

To update or switch versions, run `webi crush@stable` (or `@v0.50`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/crush
~/.local/opt/crush-VERSION/bin/crush
~/.config/crush/
```

## Cheat Sheet

> `crush` is a terminal-based AI coding assistant built on the Charm ecosystem.
> It connects to LLM providers (OpenAI, Anthropic, Google, Groq, local models
> via Ollama) and gives you a beautiful TUI for writing, reviewing, and
> refactoring code — with LSP support, MCP extensions, and session management.

### How to Get Started

1. Launch crush in your project directory:

   ```sh
   cd ~/your-project
   crush
   ```

   On first run, crush will guide you through setting up your preferred LLM
   provider.

2. Alternatively, set an API key beforehand:

   ```sh
   export OPENAI_API_KEY="sk-..."
   # or
   export ANTHROPIC_API_KEY="sk-ant-..."
   ```

### How to Configure Providers

crush supports multiple LLM providers. Configure them via the TUI or by editing
`~/.config/crush/config.yaml`:

```yaml
providers:
  - id: openai
    name: OpenAI
    type: openai
    base_url: https://api.openai.com/v1
    api_key: sk-...

  - id: anthropic
    name: Anthropic
    type: anthropic
    base_url: https://api.anthropic.com
    api_key: sk-ant-...

default_provider: openai
default_model: gpt-4o
```

### How to Switch Models Mid-Session

crush lets you switch LLMs while preserving context:

1. Press `Ctrl+M` to open the model selector
2. Choose a different provider or model
3. Continue your conversation with the new model

### How to Use LSP Features

crush integrates with Language Server Protocols for enhanced code intelligence:

- **Go to Definition**: Navigate to function/variable definitions
- **Find References**: See where code is used across your project
- **Code Actions**: Get suggestions for fixes and refactorings
- **Diagnostics**: See errors and warnings inline

LSP features work automatically when crush detects supported languages (Go,
TypeScript, Python, Rust, and more).

### How to Use with Local Models (Optional)

For fully local AI coding with no API calls, use [ollama](../ollama/) (also
available via webi):

```sh
# Install ollama separately (optional)
curl https://webi.sh/ollama | sh
source ~/.config/envman/PATH.env
```

1. Start the `ollama` server and pull a model:

   ```sh
   ollama serve &
   ollama pull qwen2.5-coder:32b
   ```

2. Configure crush to use the local model:

   ```yaml
   providers:
     - id: ollama
       name: Ollama
       type: ollama
       base_url: http://localhost:11434

   default_provider: ollama
   default_model: qwen2.5-coder:32b
   ```

3. Launch crush — it will connect to your local Ollama instance:

   ```sh
   crush
   ```

### How to Use Sessions

crush maintains multiple work sessions per project:

```sh
# List sessions
crush sessions

# Start a named session
crush --session feature-auth

# Resume last session
crush --resume
```

### How to Add MCP Capabilities

crush supports Model Context Protocol (MCP) extensions for additional tools:

1. Create `~/.config/crush/mcp.yaml`:

   ```yaml
   servers:
     - id: filesystem
       name: Filesystem
       command: npx
       args: [-y, @modelcontextprotocol/server-filesystem, /home/user/projects]

     - id: http
       name: HTTP Client
       command: npx
       args: [-y, @modelcontextprotocol/server-fetch]
   ```

2. Restart crush to load the MCP servers

### Useful Key Bindings

| Key      | Action                           |
| -------- | -------------------------------- |
| `Enter`  | Send message                     |
| `Ctrl+M` | Switch model/provider            |
| `Ctrl+S` | Save session                     |
| `Ctrl+L` | Clear screen                     |
| `Ctrl+C` | Cancel current operation         |
| `Ctrl+D` | Exit crush                       |
| `Ctrl+E` | Open editor for multi-line input |
| `Ctrl+R` | Search message history           |
| `Ctrl+T` | Toggle LSP diagnostics           |

### How to Configure Advanced Features

Edit `~/.config/crush/config.yaml`:

```yaml
# Enable debug logging
debug: true

# Configure session directory
session_dir: ~/.config/crush/sessions

# Set custom editor
editor: vim

# Configure LSP timeout
lsp_timeout: 5s

# Enable/disable features
features:
  lsp: true
  mcp: true
  git_integration: true
```

### Features

- **Multi-Model**: Switch between OpenAI, Anthropic, Google, Groq, or local
  models
- **Session-Based**: Multiple work sessions per project with context
  preservation
- **LSP-Enhanced**: Language server integration for code intelligence
- **MCP Extensions**: Add custom tools via Model Context Protocol
- **Git-Aware**: Automatically includes git context in conversations
- **Works Everywhere**: First-class support on macOS, Linux, Windows
  (PowerShell/WSL), Android, BSD

### System Requirements

- 8GB+ RAM recommended for local models
- Network connection for cloud LLM providers (or use Ollama for offline)
- Terminal with UTF-8 and 256-color support

### Troubleshooting

If crush doesn't start:

```sh
# Check configuration
crush --check-config

# Reset to defaults
rm -rf ~/.config/crush/config.yaml
crush
```

If LSP features aren't working:

```sh
# Check LSP status
crush --lsp-status

# Install language servers
# (e.g., for TypeScript)
npm install -g typescript-language-server
```
