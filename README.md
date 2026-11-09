## Greetings, Fellow Developer! 👋

You've stumbled upon my treasure trove of personal configurations essential for setting up my development environments on any machine. Designed with precision and tailored for efficiency, these settings are here to streamline your workflow. Feel free to adapt and tweak them as you see fit.

## Neovim Setup 🛠️

### Dive into My Environment
Built on **[LazyVim](https://www.lazyvim.org/)**, with **[Claude Code](https://claude.com/claude-code)** wired in as a side panel that knows what I'm looking at.

### Prerequisites 📋
- **Neovim (v0.12+)** compiled with **LuaJIT**. 🚀
- **Git**, a **C compiler** and **Node.js** (Mason installs the language servers with npm). 🔄
- **[ripgrep](https://github.com/BurntSushi/ripgrep)**, **[fd](https://github.com/sharkdp/fd)**, **[fzf](https://github.com/junegunn/fzf)**, **[lazygit](https://github.com/jesseduffield/lazygit)** and the **[tree-sitter CLI](https://github.com/tree-sitter/tree-sitter)**. 🔍
- A **[Nerd Font](https://www.nerdfonts.com/)** set in the terminal (I use JetBrainsMono Nerd Font). 🎨
- The **Claude Code CLI** on the `PATH` (falls back to `~/.local/bin/claude`). 🤖

### Languages 🌈
Enabled through LazyVim extras in `nvim/lazyvim.json`: TypeScript (vtsls), Tailwind, Prisma, SQL with dadbod, JSON, YAML, Markdown, Docker, TOML, Git, ESLint, Prettier, DAP and neotest with vitest. Toggle them with `:LazyExtras`.

### Claude Code 🤖
**[claudecode.nvim](https://github.com/coder/claudecode.nvim)** connects the CLI to the editor the same way the VS Code extension does: Claude sees the current file, cursor and selection, and proposes edits as diffs (`:w` accepts, `:q` rejects).

| Key | Action |
| --- | --- |
| `Ctrl+/` | Show or hide Claude from anywhere, keeping the session |
| `<leader>as` (visual) | Send the selection to the chat and jump there |
| `<leader>aq` | Ask about the selection, or the function under the cursor, without leaving the code |
| `<leader>aa` / `<leader>ad` | Accept or reject a proposed diff |
| `<leader>am` | Pick the model |
| `Ctrl+q` / `Ctrl+h` / `q` | Inside the panel: normal mode, back to the code, hide |

The plain shell terminal lives on `<leader>ft`.

### Worktrees and sessions 🌳
Agents work in their own git worktrees, and each worktree keeps its own Claude session and its own buffers inside Neovim.

**Starting.** Running `nvim` with no file in a repository that has more than one worktree opens the worktree panel first. Each entry shows what is going on there: the Claude panel open in this Neovim, background agents still running (from `claude agents --json`, matched by the directory in their transcript), a session open in another terminal, the last conversation in that folder and the number of changed files. The preview lists the sessions and the changes. `Esc` stays where Neovim started.

**Choosing a session.** The first time Claude opens in a worktree (`Ctrl+/`), Neovim offers to enter a running background agent there (`claude attach`), continue the last conversation (`--continue`), pick an older one (`--resume`) or start a new one. Switching worktrees keeps each Claude running, hides its panel and brings it back on return. Selections and mentions only reach the Claude of the current worktree.

**New worktrees** go to `.claude/worktrees/<name>` on branch `claude/<name>`, from `origin/HEAD` (or `HEAD` without a remote), and open a new Claude conversation. If the repository does not ignore that folder, it is added to `.git/info/exclude`.

| Key | Action |
| --- | --- |
| `<leader>gw` / `:Worktrees` | Worktree panel: enter, continue or create (`Ctrl+n`) |
| `<leader>gW` | Back to the previous worktree |
| `<leader>aw` | Turn following changes on or off |
| `<leader>gs` / `<leader>gd` | Changed files / changed hunks in the current worktree |

Buffers and windows of each worktree are saved with persistence.nvim when leaving it and restored when coming back.

**Live follow.** Neovim watches the root of the worktree it is in. When any process (Claude in the panel, a background agent, a formatter) changes a file, the buffer reloads, the changed lines flash and the window jumps there, unless I'm typing. Git-ignored paths are skipped, batches of more than five files only raise a notice, and unsaved edits are never overwritten. The statusline shows the branch when inside a linked worktree.

### Aesthetic Touch 🎨
- **Theme**: Currently, I’m all about the **[Tokyo Night](https://github.com/folke/tokyonight.nvim)** theme. It’s visually stunning and perfect for long coding sessions.

### Terminals of Choice 🖥️
- **[kitty](https://github.com/kovidgoyal/kitty)** and **[wezterm](https://github.com/wez/wezterm)** on Linux and macOS deliver exceptional performance.
- **[alacritty](https://github.com/alacritty/alacritty)** and **[iterm2](https://iterm2.com/)** round out my top picks for their robust color support and smooth integration.

## Engage and Contribute 💬
Should you have suggestions or improvements, I warmly invite you to open a Pull Request. Let’s collaborate to refine these setups even further!

## Discover More 🌐
Curious about my projects or looking to connect? Visit my portfolio at [paulomartins.dev](https://paulomartins.dev) and let’s start a conversation!
