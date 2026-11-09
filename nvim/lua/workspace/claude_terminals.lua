local root = require("workspace.root")
local sessions = require("workspace.sessions")

local M = {}

local terminals = {}
local root_clients = {}
local queued = {}
local routing_installed = false

local function server()
  return require("claudecode.server.init")
end

local function connected_clients()
  local state = server().state
  return state and state.server and state.server.clients or {}
end

local function live(key)
  local entry = terminals[key]
  if entry and entry.term:buf_valid() then
    return entry
  end
  terminals[key] = nil
end

local function client_of(key)
  local id = root_clients[key]
  if not id then
    return nil
  end
  local client = connected_clients()[id]
  if not client then
    root_clients[key] = nil
  end
  return client
end

local function any_mapped_client()
  for key in pairs(root_clients) do
    if client_of(key) then
      return true
    end
  end
  return false
end

local function is_mapped(client_id)
  return vim.tbl_contains(vim.tbl_values(root_clients), client_id)
end

local function flush(key)
  local client = client_of(key)
  if not client then
    return
  end
  for _, message in ipairs(queued[key] or {}) do
    server().send(client, message.method, message.params)
  end
  queued[key] = nil
end

local function install_routing()
  if routing_installed then
    return
  end
  local claude_server = server()
  local broadcast_to_all = claude_server.broadcast
  claude_server.broadcast = function(method, params)
    if not any_mapped_client() then
      return broadcast_to_all(method, params)
    end
    local key = root.key()
    local client = client_of(key)
    if client then
      return claude_server.send(client, method, params)
    end
    if method == "at_mentioned" then
      queued[key] = queued[key] or {}
      table.insert(queued[key], { method = method, params = params })
    end
    return true
  end
  routing_installed = true
end

local function claim_next_client(key)
  local known = {}
  for id in pairs(connected_clients()) do
    known[id] = true
  end
  local timer = vim.uv.new_timer()
  local function stop()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
  timer:start(
    200,
    200,
    vim.schedule_wrap(function()
      for id in pairs(connected_clients()) do
        if not known[id] and not is_mapped(id) then
          root_clients[key] = id
          stop()
          flush(key)
          return
        end
      end
      if not live(key) then
        stop()
      end
    end)
  )
end

local function window_config(config, focus)
  return vim.tbl_deep_extend("force", {
    position = config.split_side or "right",
    width = config.split_width_percentage or 0.38,
    height = 0,
    relative = "editor",
    enter = focus,
    keys = {
      claude_new_line = {
        "<S-CR>",
        function()
          vim.api.nvim_feedkeys("\\", "t", true)
          vim.defer_fn(function()
            vim.api.nvim_feedkeys("\r", "t", true)
          end, 10)
        end,
        mode = "t",
        desc = "New line",
      },
    },
  }, config.snacks_win_opts or {})
end

local function spawn(key, cmd, env, config, focus, connects_to_ide)
  install_routing()
  local term = Snacks.terminal.open(cmd, {
    cwd = key,
    env = env,
    start_insert = focus,
    auto_insert = config.auto_insert ~= false,
    auto_close = true,
    win = window_config(config, focus),
  })
  terminals[key] = { term = term }
  if connects_to_ide then
    claim_next_client(key)
  end
end

function M.own_pids()
  local pids = {}
  for key in pairs(terminals) do
    local entry = live(key)
    local channel = entry and vim.bo[entry.term.buf].channel
    local ok, pid = pcall(vim.fn.jobpid, channel or 0)
    if ok and pid > 0 then
      pids[pid] = true
      local children = vim.system({ "pgrep", "-P", tostring(pid) }, { text = true }):wait()
      for child in (children.stdout or ""):gmatch("%d+") do
        pids[tonumber(child)] = true
      end
    end
  end
  return pids
end

local function launch_options(key, cmd)
  local worktree_paths = vim.tbl_map(function(worktree)
    return worktree.path
  end, require("workspace.worktrees").list())
  if #worktree_paths == 0 then
    worktree_paths = { key }
  end
  local group = sessions.by_worktree(worktree_paths, M.own_pids())[key] or { attachable = {} }

  local options = {}
  for _, agent in ipairs(group.attachable) do
    options[#options + 1] = {
      label = ('Entrar no agente "%s" (%s)'):format(agent.name or agent.id, agent.status),
      cmd = ("%s attach %s"):format(cmd, vim.fn.shellescape(agent.id)),
      connects_to_ide = false,
    }
  end
  local last = sessions.last_conversation(key)
  if last then
    options[#options + 1] = {
      label = "Continuar a última conversa (" .. sessions.relative_time(last) .. ")",
      cmd = cmd .. " --continue",
      connects_to_ide = true,
    }
    options[#options + 1] =
      { label = "Escolher uma conversa anterior", cmd = cmd .. " --resume", connects_to_ide = true }
  end
  options[#options + 1] = { label = "Nova conversa", cmd = cmd, connects_to_ide = true }
  return options
end

local function start(key, cmd, env, config, focus)
  local has_explicit_args = cmd ~= sessions.claude_bin()
  if has_explicit_args then
    return spawn(key, cmd, env, config, focus, true)
  end
  local options = launch_options(key, cmd)
  if #options == 1 then
    return spawn(key, options[1].cmd, env, config, focus, true)
  end
  vim.ui.select(options, {
    prompt = "Claude em " .. vim.fs.basename(key),
    format_item = function(option)
      return option.label
    end,
  }, function(choice)
    if choice then
      spawn(key, choice.cmd, env, config, focus, choice.connects_to_ide)
    end
  end)
end

local function show(entry, focus)
  local origin = vim.api.nvim_get_current_win()
  entry.term:show()
  if focus then
    entry.term:focus()
  elseif vim.api.nvim_win_is_valid(origin) then
    vim.api.nvim_set_current_win(origin)
  end
end

function M.setup(_)
  install_routing()
end

function M.is_available()
  return Snacks ~= nil and Snacks.terminal ~= nil
end

function M.get_active_bufnr()
  local entry = live(root.key())
  return entry and entry.term.buf or nil
end

function M.open(cmd, env, config, focus)
  focus = focus ~= false
  local key = root.key()
  local entry = live(key)
  if entry then
    return show(entry, focus)
  end
  start(key, cmd, env, config, focus)
end

function M.close()
  local entry = live(root.key())
  if entry then
    entry.term:close()
  end
end

function M.simple_toggle(cmd, env, config)
  local key = root.key()
  local entry = live(key)
  if entry and entry.term:win_valid() then
    return entry.term:hide()
  end
  if entry then
    return show(entry, true)
  end
  start(key, cmd, env, config, true)
end

function M.focus_toggle(cmd, env, config)
  local entry = live(root.key())
  if entry and entry.term:win_valid() and vim.api.nvim_get_current_win() == entry.term.win then
    return entry.term:hide()
  end
  M.open(cmd, env, config, true)
end

function M.ensure_visible()
  local entry = live(root.key())
  if entry and not entry.term:win_valid() then
    show(entry, false)
  end
end

function M.has(key)
  return live(key) ~= nil
end

function M.ready(key)
  key = key or root.key()
  return client_of(key) ~= nil and queued[key] == nil
end

function M.leave(key)
  for other in pairs(terminals) do
    local entry = live(other)
    if entry then
      if other == key then
        entry.visible_on_leave = entry.term:win_valid()
      end
      if entry.term:win_valid() then
        entry.term:hide()
      end
    end
  end
end

function M.enter(key)
  local entry = live(key)
  if entry and entry.visible_on_leave then
    show(entry, false)
  end
end

return M
