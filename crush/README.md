---
title: crush
homepage: https://github.com/charmbracelet/crush
tagline: |
  crush: A terminal-based AI coding assistant from Charm.
---

To update or switch versions, run `webi crush@stable` (or `@v0.51`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/crush
~/.local/opt/crush-VERSION/bin/crush
~/.local/share/man/man1/crush.1.gz
~/.local/share/bash-completion/completions/crush
~/.local/share/zsh/site-functions/_crush
~/.config/fish/completions/crush.fish
```

## Cheat Sheet

> `crush` connects to LLM providers (OpenAI, Anthropic, Google, Groq, or local
> models via Ollama) and gives you a TUI for writing, reviewing, and refactoring
> code — with session management and a beautiful Charm-powered interface.

### How to Get Started

Set an API key and launch in your project directory:

```sh
export ANTHROPIC_API_KEY="sk-ant-..."
cd ~/your-project
crush
```

On first run, crush will guide you through provider setup if no key is set.

### How to Switch Models

Press `Ctrl+M` in the TUI to open the model selector. Context is preserved when
switching.

### How to Use Sessions

```sh
crush --session feature-auth
crush --resume
crush sessions
```

### How to Use with Local Models

Install [ollama](../ollama/) (also available via webi), then configure crush:

```sh
webi ollama
ollama serve &
ollama pull qwen2.5-coder:32b
```

Add to `~/.config/crush/config.yaml`:

```yaml
providers:
  - id: ollama
    name: Ollama
    type: ollama
    base_url: http://localhost:11434

default_provider: ollama
default_model: qwen2.5-coder:32b
```

### Shell Completions

Shell completions for bash, zsh, and fish are installed automatically. For zsh,
you may need to ensure the completions directory is in your fpath:

```sh
fpath=(~/.local/share/zsh/site-functions $fpath)
```
