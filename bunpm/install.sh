#!/bin/sh

set -e
set -u

__init_bunpm() {
    pkg_cmd_name="bunpm"

    pkg_dst_cmd="$HOME/.local/opt/bunpm/bin/bunpm"
    pkg_dst_dir="$HOME/.local/opt/bunpm"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/bunpm-v$WEBI_VERSION/bin/bunpm"
    pkg_src_dir="$HOME/.local/opt/bunpm-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    pkg_get_current_version() {
        if [ -f "$HOME/.local/opt/bunpm/package.json" ]; then
            grep '"version"' "$HOME/.local/opt/bunpm/package.json" | head -n 1 | cut -d '"' -f 4
        elif command -v bunpm >/dev/null 2>&1; then
            bunpm --version 2>/dev/null || echo ""
        else
            echo ""
        fi
    }

    pkg_install() {
        mkdir -p "$pkg_src_dir/bin"
        mkdir -p "$pkg_src_dir/core"

        my_repo_dir="$(find . -maxdepth 1 -type d -name "*bunpm*" | head -n 1)"
        if [ -z "$my_repo_dir" ]; then
            my_repo_dir="."
        fi

        if [ -d "$my_repo_dir/bunpm/core" ]; then
            cp -R "$my_repo_dir/bunpm/core/"* "$pkg_src_dir/core/"
            cp -R "$my_repo_dir/bunpm/platforms/linux/bin/"* "$pkg_src_dir/bin/"
        elif [ -d "$my_repo_dir/core" ]; then
            cp -R "$my_repo_dir/core/"* "$pkg_src_dir/core/"
            cp -R "$my_repo_dir/platforms/linux/bin/"* "$pkg_src_dir/bin/"
        fi

        if [ -f "$my_repo_dir/package.json" ]; then
            cp "$my_repo_dir/package.json" "$pkg_src_dir/"
        elif [ -f "$my_repo_dir/bunpm/package.json" ]; then
            cp "$my_repo_dir/bunpm/package.json" "$pkg_src_dir/"
        fi

        cat << 'EOF' > "$pkg_src_dir/bin/bunpm"
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_DIR/../core/wrapper.js" "$@"
EOF

        chmod +x "$pkg_src_dir/bin/"*
    }

    pkg_post_install() {
        webi_path_add "$pkg_src_dir/bin"
        webi_path_add "$HOME/.local/opt/bunpm/bin"
        mkdir -p "$HOME/.local/bin"
        for cmd in bunpm npm npx yarn pnpm; do
            if [ -f "$HOME/.local/opt/bunpm/bin/$cmd" ]; then
                rm -f "$HOME/.local/bin/$cmd"
                ln -s "$HOME/.local/opt/bunpm/bin/$cmd" "$HOME/.local/bin/$cmd" 2>/dev/null || cp "$HOME/.local/opt/bunpm/bin/$cmd" "$HOME/.local/bin/$cmd"
            fi
        done
    }

    pkg_done_message() {
        echo ""
        echo "Installed bunpm v$WEBI_VERSION to ~/.local/opt/bunpm/bin"
        echo "Run 'bunpm doctor' to verify your installation."
    }
}

__init_bunpm
