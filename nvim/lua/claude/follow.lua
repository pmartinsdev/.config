local M = {}

local namespace = vim.api.nvim_create_namespace("claude_follow")
local highlight_ms = 6000

M.enabled = true

local function read_payload(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local raw = file:read("*a")
  file:close()
  os.remove(path)
  local ok, payload = pcall(vim.json.decode, raw)
  return ok and payload or nil
end

local function real_path(path)
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function is_file_buffer(buf)
  return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function buffer_text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
end

local function changed_ranges(before, after)
  local ranges = {}
  for _, hunk in ipairs(vim.text.diff(before, after, { result_type = "indices" })) do
    local _, removed, first, added = unpack(hunk)
    local start = math.max(first, 1)
    ranges[#ranges + 1] = { first = start, last = start + math.max(added, 1) - 1, removed = removed, added = added }
  end
  return ranges
end

local function reload(buf)
  if vim.bo[buf].modified then
    return nil
  end
  local before, tick = buffer_text(buf), vim.api.nvim_buf_get_changedtick(buf)
  vim.cmd("silent! checktime " .. buf)
  if vim.api.nvim_buf_get_changedtick(buf) == tick then
    return nil
  end
  return changed_ranges(before, buffer_text(buf))
end

local function highlight(buf, ranges)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local marks = {}
  for _, range in ipairs(ranges) do
    local first_row = math.min(range.first, line_count) - 1
    if range.added == 0 then
      marks[#marks + 1] = vim.api.nvim_buf_set_extmark(buf, namespace, first_row, 0, {
        virt_text = { { ("  Claude removeu %d linha(s)"):format(range.removed), "DiffDelete" } },
      })
    else
      marks[#marks + 1] = vim.api.nvim_buf_set_extmark(buf, namespace, first_row, 0, {
        end_row = math.min(range.last, line_count),
        hl_group = range.removed == 0 and "DiffAdd" or "DiffChange",
        hl_eol = true,
        priority = 200,
      })
    end
  end
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) then
      for _, id in ipairs(marks) do
        pcall(vim.api.nvim_buf_del_extmark, buf, namespace, id)
      end
    end
  end, highlight_ms)
end

local function new_snippets(tool_input)
  if tool_input.new_string then
    return { tool_input.new_string }
  end
  return vim.tbl_map(function(edit)
    return edit.new_string or ""
  end, tool_input.edits or {})
end

local function find_snippet(lines, snippet)
  local snippet_lines = vim.split(snippet, "\n", { plain = true })
  for offset, anchor in ipairs(snippet_lines) do
    if vim.trim(anchor) ~= "" then
      for index, line in ipairs(lines) do
        if line:find(anchor, 1, true) then
          local first = math.max(index - offset + 1, 1)
          return { first = first, last = first + #snippet_lines - 1, removed = 1, added = #snippet_lines }
        end
      end
      return nil
    end
  end
end

local function locate_edits(buf, tool_input)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local ranges = {}
  for _, snippet in ipairs(new_snippets(tool_input)) do
    ranges[#ranges + 1] = find_snippet(lines, snippet)
  end
  return ranges
end

local function shows_code(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "" and vim.api.nvim_win_get_config(win).relative == ""
end

local function code_window()
  local current = vim.api.nvim_get_current_win()
  if shows_code(current) then
    return current
  end
  local previous = vim.fn.win_getid(vim.fn.winnr("#"))
  if previous ~= 0 and shows_code(previous) then
    return previous
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if shows_code(win) then
      return win
    end
  end
end

local function user_is_busy()
  local mode = vim.api.nvim_get_mode().mode
  local in_terminal = vim.bo.buftype == "terminal"
  return not in_terminal and mode:match("^[iRvVsSc\22\19]") ~= nil
end

local function reveal(buf, line)
  local win = code_window()
  if not win then
    return
  end
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_cursor(win, { math.min(line, vim.api.nvim_buf_line_count(buf)), 0 })
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! zz")
  end)
end

local function edited_file(payload)
  local tool_input = payload.tool_input or {}
  return tool_input.file_path or tool_input.notebook_path
end

local function reload_open_buffers()
  local reloaded = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_file_buffer(buf) then
      local ranges = reload(buf)
      if ranges and #ranges > 0 then
        highlight(buf, ranges)
        reloaded[real_path(vim.api.nvim_buf_get_name(buf))] = { buf = buf, ranges = ranges }
      end
    end
  end
  return reloaded
end

local function open_edited(path, tool_input)
  local existing = vim.fn.bufnr(path)
  if existing ~= -1 and vim.api.nvim_buf_is_loaded(existing) then
    if vim.bo[existing].modified then
      vim.notify(
        ("Claude alterou %s, mas você tem mudanças não salvas nesse arquivo"):format(vim.fn.fnamemodify(path, ":~:.")),
        vim.log.levels.WARN
      )
      return nil
    end
    return existing, {}
  end
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  vim.bo[buf].buflisted = true
  local ranges = locate_edits(buf, tool_input)
  highlight(buf, ranges)
  return buf, ranges
end

local function handle(payload)
  local reloaded = reload_open_buffers()
  local path = edited_file(payload)
  if not path then
    return
  end

  local entry = reloaded[real_path(path)]
  local buf, ranges
  if entry then
    buf, ranges = entry.buf, entry.ranges
  else
    buf, ranges = open_edited(path, payload.tool_input)
  end
  if not buf then
    return
  end

  if M.enabled and not user_is_busy() then
    reveal(buf, ranges[1] and ranges[1].first or 1)
  else
    vim.notify(("Claude editou %s"):format(vim.fn.fnamemodify(path, ":~:.")))
  end
end

function M.on_tool_use(payload_path)
  vim.schedule(function()
    local payload = read_payload(payload_path)
    if not payload then
      return
    end
    local ok, err = pcall(handle, payload)
    if not ok then
      vim.notify("claude.follow: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
  return ""
end

function M.toggle()
  M.enabled = not M.enabled
  vim.notify("Seguir edições do Claude " .. (M.enabled and "ligado" or "desligado"))
end

return M
