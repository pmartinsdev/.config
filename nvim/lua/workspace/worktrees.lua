local M = {}

local label = ""

local function real_path(path)
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function git(args, cwd)
  local result = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd or vim.fn.getcwd(), text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  return result.stdout
end

local function current_root()
  local output = git({ "rev-parse", "--show-toplevel" })
  return output and real_path(vim.trim(output)) or nil
end

local function is_inside(path, root)
  return path == root or vim.startswith(path, root .. "/")
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
      current = { path = real_path(path) }
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

local function close_buffers_from(old_root, new_root)
  local kept = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    local is_file = vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and name ~= ""
    local path = is_file and real_path(name) or nil
    if path and is_inside(path, old_root) and not is_inside(path, new_root) then
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

function M.switch(target)
  target = real_path(target)
  local old_root = current_root()
  if old_root == target then
    return
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  local relative = old_root and current_file ~= "" and vim.fs.relpath(old_root, real_path(current_file)) or nil
  local same_file = relative and target .. "/" .. relative or nil

  vim.cmd.cd(vim.fn.fnameescape(target))
  if same_file and vim.uv.fs_stat(same_file) then
    vim.cmd.edit(vim.fn.fnameescape(same_file))
  else
    vim.cmd.enew()
  end
  if old_root then
    close_buffers_from(old_root, target)
  end
end

local function describe(worktree, current)
  local marker = worktree.path == current and "● " or "  "
  local name = worktree.branch or ("detached " .. (worktree.head or ""):sub(1, 9))
  return marker .. name .. "  " .. vim.fn.fnamemodify(worktree.path, ":~")
end

function M.pick()
  local worktrees = M.list()
  if #worktrees == 0 then
    vim.notify("Este diretório não está num repositório git", vim.log.levels.WARN)
    return
  end
  local current = current_root()
  vim.ui.select(worktrees, {
    prompt = "Worktree",
    format_item = function(worktree)
      return describe(worktree, current)
    end,
  }, function(choice)
    if choice then
      M.switch(choice.path)
    end
  end)
end

local function refresh_label()
  local output = git({ "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir", "--abbrev-ref", "HEAD" })
  if not output then
    label = ""
    return
  end
  local git_dir, common_dir, branch = unpack(vim.split(vim.trim(output), "\n", { plain = true }))
  local in_linked_worktree = git_dir ~= common_dir
  label = in_linked_worktree and ("󰙅 " .. branch) or ""
end

function M.statusline()
  return label
end

function M.setup()
  vim.api.nvim_create_user_command("Worktrees", M.pick, { desc = "Switch to another git worktree" })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("workspace_worktrees", { clear = true }),
    callback = refresh_label,
  })
  refresh_label()
end

return M
