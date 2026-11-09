local root = require("workspace.root")
local sessions = require("workspace.sessions")

local M = {}

local label = ""
local previous_root
local max_listed_changes = 15

local function git(args, cwd)
  local result = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd or vim.fn.getcwd(), text = true }):wait()
  if result.code ~= 0 then
    return nil, result.stderr
  end
  return result.stdout
end

local function terminals()
  return require("workspace.claude_terminals")
end

function M.current_root()
  return root.get()
end

function M.list()
  local output = git({ "worktree", "list", "--porcelain" })
  if not output then
    return {}
  end
  local worktrees, current = {}, nil
  for line in vim.gsplit(output, "\n", { plain = true }) do
    local path = line:match("^worktree (.+)$")
    if path then
      current = { path = root.real_path(path), is_main = #worktrees == 0 }
      worktrees[#worktrees + 1] = current
    elseif current then
      current.branch = current.branch or line:match("^branch refs/heads/(.+)$")
      current.head = current.head or line:match("^HEAD (%x+)$")
      current.bare = current.bare or line == "bare"
    end
  end
  return vim.tbl_filter(function(worktree)
    return not worktree.bare
  end, worktrees)
end

local function persistence()
  local ok, module = pcall(require, "persistence")
  return ok and module or nil
end

local function has_saved_session()
  local module = persistence()
  if not module then
    return false
  end
  return vim.uv.fs_stat(module.current()) ~= nil or vim.uv.fs_stat(module.current({ branch = false })) ~= nil
end

local function hide_terminal_windows()
  for _, term in ipairs(Snacks.terminal.list()) do
    if term:win_valid() then
      term:hide()
    end
  end
end

local function close_buffers_from(old_root, new_root)
  local kept = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    local is_file = vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and name ~= ""
    local path = is_file and root.real_path(name) or nil
    if path and root.is_inside(path, old_root) and not root.is_inside(path, new_root) then
      if vim.bo[buf].modified then
        kept = kept + 1
      else
        Snacks.bufdelete({ buf = buf })
      end
    end
  end
  if kept > 0 then
    vim.notify(
      ("%d buffer(s) com mudanças não salvas continuam abertos do worktree anterior"):format(kept),
      vim.log.levels.WARN
    )
  end
end

local function reopen(target, relative_file)
  if has_saved_session() then
    persistence().load()
    return
  end
  local same_file = relative_file and target .. "/" .. relative_file or nil
  if same_file and vim.uv.fs_stat(same_file) then
    vim.cmd.edit(vim.fn.fnameescape(same_file))
  else
    vim.cmd.enew()
  end
end

function M.switch(target)
  target = root.real_path(target)
  local old_root = root.get()
  if old_root == target then
    return
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  local relative_file = old_root and current_file ~= "" and vim.fs.relpath(old_root, root.real_path(current_file))
    or nil

  vim.cmd("silent! %argdelete")
  if old_root then
    terminals().leave(old_root)
    hide_terminal_windows()
    local module = persistence()
    if module then
      pcall(module.save)
    end
  end

  previous_root = old_root
  vim.cmd.cd(vim.fn.fnameescape(target))
  if old_root then
    close_buffers_from(old_root, target)
  end
  reopen(target, relative_file)
  terminals().enter(target)
end

function M.previous()
  if not previous_root or not vim.uv.fs_stat(previous_root) then
    vim.notify("Nenhum worktree anterior nesta sessão", vim.log.levels.INFO)
    return
  end
  M.switch(previous_root)
end

local function slug(text)
  return (vim.trim(text):gsub("%s+", "-"):gsub("[^%w%-%._]", ""))
end

local function ensure_ignored(main_root, path)
  local ignored = vim.system({ "git", "-C", main_root, "check-ignore", "-q", path }):wait().code == 0
  if ignored then
    return
  end
  local common_dir = vim.trim(git({ "rev-parse", "--path-format=absolute", "--git-common-dir" }, main_root) or "")
  local exclude = common_dir .. "/info/exclude"
  vim.fn.mkdir(common_dir .. "/info", "p")
  vim.fn.writefile({ ".claude/worktrees/" }, exclude, "a")
end

local function base_ref(main_root)
  local remote_head = git({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, main_root)
  return remote_head and vim.trim(remote_head) or "HEAD"
end

local function branch_exists(main_root, branch)
  return vim.system({ "git", "-C", main_root, "show-ref", "--verify", "--quiet", "refs/heads/" .. branch }):wait().code
    == 0
end

function M.create(name, on_created)
  name = slug(name or "")
  if name == "" then
    return
  end
  local main_root = (M.list()[1] or {}).path
  if not main_root then
    vim.notify("Este diretório não está num repositório git", vim.log.levels.WARN)
    return
  end
  local path = main_root .. "/.claude/worktrees/" .. name
  local branch = "claude/" .. name
  ensure_ignored(main_root, path)

  local base = base_ref(main_root)
  local add_args = branch_exists(main_root, branch) and { "worktree", "add", path, branch }
    or { "worktree", "add", "-b", branch, path, base }
  vim.notify(("Criando o worktree %s a partir de %s"):format(name, base))

  local function add_worktree()
    vim.system(
      vim.list_extend({ "git", "-C", main_root }, add_args),
      { text = true },
      vim.schedule_wrap(function(result)
        if result.code ~= 0 then
          vim.notify("Não consegui criar o worktree: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
          return
        end
        M.switch(path)
        vim.cmd("ClaudeCode")
        if on_created then
          on_created(path)
        end
      end)
    )
  end

  if base == "HEAD" then
    return add_worktree()
  end
  local remote, remote_branch = base:match("^([^/]+)/(.+)$")
  vim.system({ "git", "-C", main_root, "fetch", "--quiet", remote, remote_branch }, {}, vim.schedule_wrap(add_worktree))
end

local function prompt_create()
  vim.ui.input({ prompt = "Nome do novo worktree (ex.: ENG-1234-assunto): " }, function(name)
    if name then
      M.create(name)
    end
  end)
end

local function display_name(worktree)
  if worktree.is_main then
    return "principal · " .. vim.fs.basename(worktree.path)
  end
  return worktree.branch or vim.fs.basename(worktree.path)
end

local function changes_of(worktree)
  return vim.system({ "git", "-C", worktree.path, "status", "--porcelain" }, { text = true })
end

local function gather()
  local worktrees = M.list()
  local paths = vim.tbl_map(function(worktree)
    return worktree.path
  end, worktrees)
  local grouped = sessions.by_worktree(paths, terminals().own_pids())
  local status_jobs = vim.tbl_map(changes_of, worktrees)
  for index, worktree in ipairs(worktrees) do
    local status = status_jobs[index]:wait()
    worktree.changes = vim.split(vim.trim(status.stdout or ""), "\n", { trimempty = true })
    worktree.sessions = grouped[worktree.path]
    worktree.last_conversation = sessions.last_conversation(worktree.path)
    worktree.has_panel = terminals().has(worktree.path)
  end
  return worktrees
end

local function summary(worktree)
  local parts = {}
  if worktree.has_panel then
    parts[#parts + 1] = "Claude aberto aqui"
  end
  local attachable = worktree.sessions.attachable
  if #attachable == 1 then
    parts[#parts + 1] = ("agente rodando: %s"):format(attachable[1].name or attachable[1].id)
  elseif #attachable > 1 then
    parts[#parts + 1] = ("%d agentes rodando"):format(#attachable)
  end
  if #worktree.sessions.elsewhere > 0 then
    parts[#parts + 1] = "sessão aberta em outro terminal"
  end
  if worktree.last_conversation then
    parts[#parts + 1] = "conversa " .. sessions.relative_time(worktree.last_conversation)
  end
  parts[#parts + 1] = #worktree.changes == 0 and "sem alterações" or (#worktree.changes .. " alterações")
  return table.concat(parts, " · ")
end

local function describe_agents(lines, title, agents)
  for _, agent in ipairs(agents) do
    lines[#lines + 1] = ("- %s: **%s** (%s)"):format(title, agent.name or agent.id, agent.status or agent.state or "?")
  end
end

local function preview_text(worktree)
  local lines = {
    "# " .. display_name(worktree),
    "",
    ("`%s` · branch `%s`"):format(vim.fn.fnamemodify(worktree.path, ":~"), worktree.branch or "detached"),
    "",
    "## Claude",
  }
  if worktree.has_panel then
    lines[#lines + 1] = "- Painel do Claude aberto neste nvim"
  end
  describe_agents(lines, "Agente rodando (dá para entrar)", worktree.sessions.attachable)
  describe_agents(lines, "Sessão aberta em outro terminal", worktree.sessions.elsewhere)
  describe_agents(lines, "Agente que já terminou", worktree.sessions.finished)
  if worktree.last_conversation then
    lines[#lines + 1] = "- Última conversa nesta pasta " .. sessions.relative_time(worktree.last_conversation)
  end
  if #lines == 5 then
    lines[#lines + 1] = "- Nenhuma sessão"
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = ("## Alterações (%d)"):format(#worktree.changes)
  for index = 1, math.min(#worktree.changes, max_listed_changes) do
    lines[#lines + 1] = "    " .. worktree.changes[index]
  end
  return table.concat(lines, "\n")
end

local function activity(worktree)
  local running = #worktree.sessions.attachable + #worktree.sessions.elsewhere
  return (worktree.has_panel and 2 or 0) + (running > 0 and 1 or 0), worktree.last_conversation or 0
end

local function by_relevance(current)
  return function(a, b)
    if (a.path == current) ~= (b.path == current) then
      return a.path == current
    end
    local a_live, a_recent = activity(a)
    local b_live, b_recent = activity(b)
    if a_live ~= b_live then
      return a_live > b_live
    end
    return a_recent > b_recent
  end
end

local function picker_items()
  local current = root.get()
  local worktrees = gather()
  table.sort(worktrees, by_relevance(current))
  local items = {}
  for _, worktree in ipairs(worktrees) do
    items[#items + 1] = {
      text = display_name(worktree) .. " " .. worktree.path,
      worktree = worktree,
      marker = worktree.path == current and "● " or "  ",
      title = display_name(worktree),
      summary = summary(worktree),
      preview = { text = preview_text(worktree), ft = "markdown" },
    }
  end
  items[#items + 1] = {
    text = "novo worktree new",
    is_new = true,
    marker = "+ ",
    title = "Novo worktree",
    summary = "a partir de " .. base_ref((worktrees[1] or {}).path or vim.fn.getcwd()),
    preview = {
      text = "# Novo worktree\n\nCria `.claude/worktrees/<nome>` no branch `claude/<nome>`, troca o nvim para ele e abre uma conversa nova do Claude.\n\nAtalho dentro desta lista: `Ctrl+n`.",
      ft = "markdown",
    },
  }
  return items
end

function M.pick()
  if #M.list() == 0 then
    vim.notify("Este diretório não está num repositório git", vim.log.levels.WARN)
    return
  end
  Snacks.picker.pick({
    title = "Worktrees",
    items = picker_items(),
    preview = "preview",
    format = function(item)
      return {
        { item.marker, "Special" },
        { item.title, "Title" },
        { "  " },
        { item.summary, "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      if item.is_new then
        prompt_create()
      else
        M.switch(item.worktree.path)
      end
    end,
    actions = {
      new_worktree = function(picker)
        picker:close()
        prompt_create()
      end,
    },
    win = { input = { keys = { ["<C-n>"] = { "new_worktree", mode = { "n", "i" } } } } },
  })
end

function M.refresh_label()
  local output = git({ "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir", "--abbrev-ref", "HEAD" })
  if not output then
    label = ""
    return
  end
  local git_dir, common_dir, branch = unpack(vim.split(vim.trim(output), "\n", { plain = true }))
  label = git_dir ~= common_dir and ("󰙅 " .. branch) or ""
end

function M.statusline()
  return label
end

local function should_offer_on_start()
  return vim.fn.argc(-1) == 0 and #M.list() > 1
end

function M.setup()
  vim.api.nvim_create_user_command("Worktrees", M.pick, { desc = "Pick, create or switch git worktrees" })
  M.refresh_label()
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      if should_offer_on_start() then
        vim.schedule(M.pick)
      end
    end,
  })
end

return M
