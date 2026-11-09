local M = {}

local connect_timeout_ms = 30000
local delivery_delay_ms = { connected = 250, starting = 1500 }
local excluded_scope_words = { "call", "invocation", "signature", "type", "parameter" }

local function is_function_like(node)
  local kind = node:type()
  if not (kind:find("function", 1, true) or kind:find("method", 1, true)) then
    return false
  end
  for _, word in ipairs(excluded_scope_words) do
    if kind:find(word, 1, true) then
      return false
    end
  end
  return true
end

local function is_callback(node)
  local parent = node:parent()
  return parent ~= nil and parent:type() == "arguments"
end

local function enclosing_scope()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok then
    return nil
  end
  while node do
    if is_function_like(node) and not is_callback(node) then
      local start_row, _, end_row = node:range()
      return start_row, end_row
    end
    node = node:parent()
  end
end

local function deliver(question, origin_win, delay_ms)
  local claudecode = require("claudecode")
  local terminal = require("claudecode.terminal")
  local deadline = vim.uv.now() + connect_timeout_ms

  local function mentions_delivered()
    return claudecode.is_claude_connected() and #(claudecode.state.mention_queue or {}) == 0
  end

  local function send()
    terminal.send_to_terminal(question)
    if vim.api.nvim_win_is_valid(origin_win) then
      vim.api.nvim_set_current_win(origin_win)
      vim.cmd("stopinsert")
    end
  end

  local function attempt()
    if mentions_delivered() then
      vim.defer_fn(send, delay_ms)
    elseif vim.uv.now() < deadline then
      vim.defer_fn(attempt, 200)
    else
      vim.notify("Claude não conectou a tempo, a pergunta não foi enviada", vim.log.levels.WARN)
    end
  end

  attempt()
end

local function ask(first_row, last_row)
  local file = vim.api.nvim_buf_get_name(0)
  local origin_win = vim.api.nvim_get_current_win()
  local question = vim.fn.input({ prompt = "Claude ❯ ", cancelreturn = "" })
  if vim.trim(question) == "" then
    return
  end

  local claudecode = require("claudecode")
  local delay_ms = claudecode.is_claude_connected() and delivery_delay_ms.connected or delivery_delay_ms.starting
  if file ~= "" and vim.bo.buftype == "" then
    claudecode.send_at_mention(file, first_row, last_row, "ask")
  else
    require("claudecode.terminal").ensure_visible()
  end
  deliver(question, origin_win, delay_ms)
end

function M.ask_selection()
  local first, last = vim.fn.line("v"), vim.fn.line(".")
  if first > last then
    first, last = last, first
  end
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  ask(first - 1, last - 1)
end

function M.ask_here()
  ask(enclosing_scope())
end

return M
