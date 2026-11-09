local root = require("workspace.root")

local M = {}

local transcript_tail_bytes = 65536

function M.claude_bin()
  local found = vim.fn.exepath("claude")
  return found ~= "" and found or vim.fn.expand("~/.local/bin/claude")
end

local function config_dir()
  return vim.env.CLAUDE_CONFIG_DIR or vim.fn.expand("~/.claude")
end

local function project_dir(path)
  return config_dir() .. "/projects/" .. path:gsub("[^%w]", "-")
end

local function read_tail(path, bytes)
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end
  local size = vim.uv.fs_fstat(fd).size
  local offset = math.max(size - bytes, 0)
  local data = vim.uv.fs_read(fd, size - offset, offset)
  vim.uv.fs_close(fd)
  return data
end

local function last_cwd(session_id)
  local transcript = vim.fn.glob(config_dir() .. "/projects/*/" .. session_id .. ".jsonl", false, true)[1]
  if not transcript then
    return nil
  end
  local cwd
  for value in (read_tail(transcript, transcript_tail_bytes) or ""):gmatch('"cwd":"(.-)"') do
    cwd = value
  end
  return cwd
end

function M.fetch_agents()
  local result = vim.system({ M.claude_bin(), "agents", "--json", "--all" }, { text = true }):wait()
  if result.code ~= 0 then
    return {}
  end
  local ok, agents = pcall(vim.json.decode, result.stdout)
  return ok and type(agents) == "table" and agents or {}
end

local function is_running(agent)
  return agent.status ~= nil and agent.status ~= vim.NIL
end

local function owning_worktree(path, worktree_paths)
  local owner
  for _, worktree in ipairs(worktree_paths) do
    if root.is_inside(path, worktree) and (not owner or #worktree > #owner) then
      owner = worktree
    end
  end
  return owner
end

function M.by_worktree(worktree_paths, own_pids)
  local grouped = {}
  for _, path in ipairs(worktree_paths) do
    grouped[path] = { attachable = {}, elsewhere = {}, finished = {} }
  end
  for _, agent in ipairs(M.fetch_agents()) do
    local cwd = root.real_path(last_cwd(agent.sessionId or "") or agent.cwd or "")
    local owner = owning_worktree(cwd, worktree_paths)
    local is_own_panel = own_pids[agent.pid] == true
    if owner and not is_own_panel then
      local group = grouped[owner]
      if not is_running(agent) then
        table.insert(group.finished, agent)
      elseif agent.kind == "background" then
        table.insert(group.attachable, agent)
      else
        table.insert(group.elsewhere, agent)
      end
    end
  end
  return grouped
end

function M.last_conversation(path)
  local ok, entries = pcall(vim.fs.dir, project_dir(path))
  if not ok then
    return nil
  end
  local newest
  for name, kind in entries do
    if kind == "file" and name:match("%.jsonl$") then
      local stat = vim.uv.fs_stat(project_dir(path) .. "/" .. name)
      if stat and (not newest or stat.mtime.sec > newest) then
        newest = stat.mtime.sec
      end
    end
  end
  return newest
end

function M.relative_time(epoch_seconds)
  local elapsed = os.time() - epoch_seconds
  if elapsed < 3600 then
    return ("há %d min"):format(math.max(math.floor(elapsed / 60), 1))
  end
  if elapsed < 86400 then
    return ("há %d h"):format(math.floor(elapsed / 3600))
  end
  return ("há %d d"):format(math.floor(elapsed / 86400))
end

return M
