---
name: crush
description:
  Glamorous terminal-based AI coding assistant from Charm with LSP integration,
  MCP extensions, session management, and beautiful TUI. Use when the user wants
  a polished terminal AI coding experience.
homepage: https://github.com/charmbracelet/crush
---

# Crush

Your new coding bestie in the terminal — built on the Charm ecosystem, powering
25k+ applications. Beautiful TUI with LSP integration, MCP extensions, and
multi-model LLM support.

## When to Use

- User wants a polished, beautiful terminal AI coding experience
- User needs LSP-enhanced code intelligence (go-to-definition, references,
  diagnostics)
- User wants session-based workflow with context preservation across multiple
  work sessions
- User needs MCP (Model Context Protocol) extensions for custom tools
- User wants to switch LLM providers mid-conversation while preserving context
- User values aesthetic terminal UIs (Charm ecosystem: Bubble Tea, Lip Gloss)
- User wants first-class support across all platforms (macOS, Linux, Windows,
  BSD, Android)

## Installation

```sh
curl https://webi.sh/crush | sh
source ~/.config/envman/PATH.env
```

## Quick Start

1. **Launch in project directory**:

   ```sh
   cd ~/your-project
   crush
   ```

2. **First-run setup** — Crush will guide you through LLM provider configuration

3. **Or set API key beforehand**:
   ```sh
   export OPENAI_API_KEY="sk-..."
   # or
   export ANTHROPIC_API_KEY="sk-ant-..."
   ```

## Configuration

### Provider Setup

Edit `~/.config/crush/config.yaml`:

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

  - id: groq
    name: Groq
    type: openai
    base_url: https://api.groq.com/openai/v1
    api_key: gsk_...

default_provider: openai
default_model: gpt-4o
```

### Local Models with Ollama (Optional)

For offline AI coding with no API calls:

```sh
# Install Ollama separately
curl https://webi.sh/ollama | sh

# Start server and pull model
ollama serve &
ollama pull qwen2.5-coder:32b
```

Configure crush to use local model:

```yaml
providers:
  - id: ollama
    name: Ollama
    type: ollama
    base_url: http://localhost:11434

default_provider: ollama
default_model: qwen2.5-coder:32b
```

### LSP Configuration

Crush automatically detects and uses LSP servers when available. Install
language servers for enhanced intelligence:

```sh
# TypeScript/JavaScript
npm install -g typescript-language-server

# Python
pip install python-lsp-server

# Go
go install golang.org/x/tools/gopls@latest

# Rust
rustup component add rust-analyzer
```

LSP features work automatically once language servers are installed.

## MCP Extensions

Add custom tools via Model Context Protocol:

Create `~/.config/crush/mcp.yaml`:

```yaml
servers:
  - id: filesystem
    name: Filesystem Access
    command: npx
    args: [-y, @modelcontextprotocol/server-filesystem, /home/user/projects]

  - id: http
    name: HTTP Client
    command: npx
    args: [-y, @modelcontextprotocol/server-fetch]

  - id: database
    name: PostgreSQL
    command: npx
    args: [-y, @modelcontextprotocol/server-postgres]
```

Restart crush to load MCP servers.

## Session Management

Crush maintains multiple work sessions per project:

```sh
# List all sessions
crush sessions

# Start a named session
crush --session feature-auth

# Resume last session
crush --resume

# Delete a session
crush sessions delete feature-auth
```

Sessions preserve:

- Conversation history
- File context
- Model selection
- LSP state

## Key Features

| Feature            | Description                                                   |
| ------------------ | ------------------------------------------------------------- |
| **Multi-Model**    | OpenAI, Anthropic, Google, Groq, Ollama — switch mid-session  |
| **Session-Based**  | Multiple named sessions per project with context preservation |
| **LSP-Enhanced**   | Go-to-definition, find-references, diagnostics, code actions  |
| **MCP Extensions** | Add custom tools via Model Context Protocol                   |
| **Git-Aware**      | Automatically includes git context in conversations           |
| **Beautiful TUI**  | Built on Charm's Bubble Tea framework                         |
| **Cross-Platform** | First-class support on macOS, Linux, Windows, BSD, Android    |

## Common Workflows

### Feature Implementation with LSP

```sh
crush --session feature-payments
# Crush uses LSP to:
# - Navigate to definitions
# - Find all references
# - Show type information
# - Suggest code actions
```

### Switch Models Mid-Session

```sh
crush
# In TUI: Press Ctrl+M to open model selector
# Switch from gpt-4o to claude-sonnet-4-5
# Conversation context is preserved
```

### Debug with LSP Diagnostics

```sh
crush
# In TUI: Press Ctrl+T to toggle LSP diagnostics
# See errors and warnings inline
# Ask crush to fix specific issues
```

### Multi-Session Workflow

```sh
# Terminal 1: Work on authentication
crush --session auth

# Terminal 2: Work on payment integration
crush --session payments

# Terminal 3: Bug fix session
crush --session bugfix-123
```

## Integration with Other Tools

### With Ollama (Local Models)

Requires `ollama` to be running:

```sh
ollama serve &  # Keep running in background
crush           # Will connect to local Ollama
```

### With Git

Crush automatically includes:

- Current branch
- Uncommitted changes
- Recent commits
- Diff context

### With LSP Servers

Crush integrates with any LSP-compliant language server:

- **Go**: gopls
- **TypeScript**: typescript-language-server
- **Python**: python-lsp-server, pyright
- **Rust**: rust-analyzer
- **C/C++**: clangd
- **Java**: jdtls

### With MCP Servers

Extend crush with Model Context Protocol servers:

- Filesystem access
- HTTP client
- Database queries
- Custom APIs
- Shell commands

## Key Bindings

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

## Files Created

```text
~/.config/envman/PATH.env           # PATH configuration
~/.local/bin/crush                  # Symlink to versioned binary
~/.local/opt/crush-VERSION/         # Installed binary
~/.config/crush/config.yaml         # Main configuration
~/.config/crush/mcp.yaml            # MCP extensions (optional)
~/.config/crush/sessions/           # Session data
```

## Advanced Configuration

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
  syntax_highlighting: true
  auto_save: true

# Performance tuning
performance:
  max_context_tokens: 128000
  stream_responses: true
  cache_embeddings: true
```

## Comparison with Alternatives

| Tool                         | Crush                               | OpenCode       | Cursor                |
| ---------------------------- | ----------------------------------- | -------------- | --------------------- |
| **Interface**                | Beautiful Charm TUI                 | Terminal TUI   | VS Code fork          |
| **LSP Integration**          | ✅ Full                             | ❌             | ✅                    |
| **MCP Extensions**           | ✅ Native                           | ❌             | ❌                    |
| **Session Management**       | ✅ Multi-session                    | Single session | Workspace-based       |
| **Local Models**             | ✅ Via Ollama                       | ✅ Via Ollama  | ❌                    |
| **Mid-Session Model Switch** | ✅ With context                     | ❌             | ❌                    |
| **Platform Support**         | macOS, Linux, Windows, BSD, Android | macOS, Linux   | macOS, Linux, Windows |
| **UI Polish**                | ⭐⭐⭐⭐⭐ Charm ecosystem          | ⭐⭐⭐         | ⭐⭐⭐⭐              |

## Best Practices

1. **Use sessions for parallel work** — Separate sessions for features, bugs,
   experiments
2. **Install LSP servers** — Maximize code intelligence with language servers
3. **Configure MCP early** — Add filesystem and HTTP MCP servers for full
   capabilities
4. **Use Ctrl+M liberally** — Switch models based on task complexity
5. **Enable git integration** — Let crush see your commit history for better
   context
6. **Save sessions regularly** — Use Ctrl+S to preserve important conversations

## Troubleshooting

**Crush won't start:**

```sh
# Check if binary is in PATH
which crush

# Verify configuration is valid
crush --check-config

# Reset to defaults
rm -rf ~/.config/crush/config.yaml
crush
```

**LSP features not working:**

```sh
# Check LSP status
crush --lsp-status

# Install language server (e.g., TypeScript)
npm install -g typescript-language-server

# Verify LSP is enabled in config
grep lsp ~/.config/crush/config.yaml
```

**MCP servers not loading:**

```sh
# Check MCP configuration
cat ~/.config/crush/mcp.yaml

# Test MCP server manually
npx -y @modelcontextprotocol/server-filesystem /tmp

# Enable debug logging
echo "debug: true" >> ~/.config/crush/config.yaml
```

**Ollama connection failed:**

```sh
# Check if Ollama is running
curl http://localhost:11434/api/version

# Start Ollama if needed
ollama serve &

# Verify crush config points to correct URL
grep ollama ~/.config/crush/config.yaml
```

## System Requirements

| Requirement  | Minimum                | Recommended            |
| ------------ | ---------------------- | ---------------------- |
| **RAM**      | 4GB                    | 8GB+                   |
| **Storage**  | 100MB                  | 500MB+ (with sessions) |
| **Network**  | Optional (with Ollama) | Required (cloud LLMs)  |
| **Terminal** | UTF-8, 256-color       | True color             |

## Resources

- GitHub: https://github.com/charmbracelet/crush
- Charm Ecosystem: https://charm.sh
- Model Context Protocol: https://modelcontextprotocol.io
- LSP Specification: https://microsoft.github.io/language-server-protocol/

## Related Webi Installers

- `ollama` — Local LLM server for offline AI coding
- `node` — Required for MCP extensions via npx
- `git` — Version control integration
- `gum` — Charm's shell scripting toolkit (pairs well with crush)
- `vhs` — Charm's terminal recorder (great for demos)
