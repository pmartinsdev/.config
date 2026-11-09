#!/bin/sh
[ -n "$NVIM" ] || exit 0
payload=$(mktemp "${TMPDIR:-/tmp}/claude-follow.XXXXXX") || exit 0
cat > "$payload"
nvim --clean --headless --server "$NVIM" --remote-expr "v:lua.require'claude.follow'.on_tool_use('$payload')" >/dev/null 2>&1 || rm -f "$payload"
exit 0
