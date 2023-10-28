---
title: ollama
homepage: https://github.com/jmorganca/ollama
tagline: |
  ollama is a golang LLM server built for ease of use.
---

To update or switch versions, run `webi ollama@stable` (or `@v0.1.5`, etc).

## Cheat Sheet

> `ollama` is an LLM serving platform written in golang. It makes LLMs built on
> Llama standards easy to run with an API.

To get started quickly with the open source LLM Mistral-7b as an example is two
commands.

1. Open **TWO Terminals**
2. In the **first**, start the `ollama` server
   ```sh
   OLLAMA_ORIGINS='*' OLLAMA_HOST=localhost:11434 ollama serve
   ```
3. In the **second**, run the `ollama` CLI (using the Mistral-7b model)
   ```sh
   ollama pull mistral
   ollama run mistral
   ```

![](https://user-images.githubusercontent.com/122831/278840139-eb3987b3-aeda-45ee-8cd2-06045c632386.png)

## Table of Contents

- Files
- ChatGPT-style Web UI
- System Notes
- Models to Try
- As a Network API

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/ollama
~/.ollama/models/
```

### How to Use a ChatGPT-style Web Interface

There are [many Ollama UIs][ollama-uis] to choose from, but `ollama-webui` is
easy to start with (and can be built as a static page):

![](https://user-images.githubusercontent.com/122831/278840488-684ffdb9-c527-4671-9072-8f5c5e823437.png)

[ollama-uis]:
  https://github.com/jmorganca/ollama/issues/875#issuecomment-1778045758

1. Install [`node`](../node/)
   ```sh
   webi node@lts
   source ~/.config/envman/PATH.env
   ```
2. Clone and enter the `ollama-webui` repo
   ```sh
   git clone https://github.com/ollama-webui/ollama-webui.git ./ollama-webui/
   pushd ./ollama-webui/
   ```
3. Install and start the project
   ```sh
   cp -RPp ./example.env ./.env
   npm clean-install
   npm run dev
   ```
4. Enjoy!
   - <http://localhost:5173/>

Note: Be sure to run `ollama` with CORS enabled:

```sh
OLLAMA_ORIGINS='*' OLLAMA_HOST=localhost:11434 ollama serve
```

## System Notes

You'll need a fairly modern computer. An Apple M1 Air works great.

- 8GB+ RAM
- 4GB+ Storage
- Models range between 3GB and 30GB+ \
  (they can take a while to download, and _several_ seconds to initialize)

### How to Downloads Other Models

See the list at <https://ollama.ai/library>.

For example, we could try `sqlcoder`, or `orca-mini` (because it's small):

```sh
ollama pull sqlcoder
ollama run sqlcoder
```

```sh
ollama pull orca-mini
ollama run orca-mini
```

### How to Use as an API on a Network

If you'd like `ollama` to be accessible beyond `localhost` (`127.0.0.1`):

- set the host to `0.0.0.0`, which makes it accessible to _ALL_ networks
- you may wish to **limit origins**

```sh
# fully open to all
OLLAMA_ORIGINS='*' OLLAMA_HOST=0.0.0.0:11435 ollama serve

# restrict browsers (not APIs) to requests from https://example.com
OLLAMA_ORIGINS='https://example.com' OLLAMA_HOST=0.0.0.0:11435 ollama serve
```

See also:

- API Docs: <https://github.com/jmorganca/ollama/blob/main/docs/api.md>
