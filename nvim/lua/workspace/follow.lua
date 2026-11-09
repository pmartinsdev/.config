local M = {}

local namespace = vim.api.nvim_create_namespace("workspace_follow")
local highlight_ms = 6000
local debounce_ms = 200
local max_files_to_follow = 5
local skipped_dirs = { ".git", "node_modules", ".next", ".turbo", "dist", "build", "coverage" }

M.enabled = true
M.root = nil

local watcher
local debounce_timer
local pending = {}
local sequence = 0
local recent_writes = {}

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
        virt_text = { { ("  %d linha(s) removida(s)"):format(range.removed), "DiffDelete" } },
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

local function uncommitted_ranges(path)
  local result = vim
    .system({ "git", "-C", M.root, "diff", "--no-color", "--unified=0", "HEAD", "--", path }, { text = true })
    :wait()
  local ranges = {}
  for removed, first, added in (result.stdout or ""):gmatch("@@ %-%d+,?(%d*) %+(%d+),?(%d*) @@") do
    local removed_count = removed == "" and 1 or tonumber(removed)
    local added_count = added == "" and 1 or tonumber(added)
    local start = math.max(tonumber(first), 1)
    ranges[#ranges + 1] =
      { first = start, last = start + math.max(added_count, 1) - 1, removed = removed_count, added = added_count }
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

local function display_path(path)
  return vim.fn.fnamemodify(path, ":~:.")
end

local function in_skipped_dir(relative)
  for segment in relative:gmatch("[^/]+") do
    if vim.list_contains(skipped_dirs, segment) then
      return true
    end
  end
  return false
end

local function ignored_by_git(paths)
  local result = vim
    .system({ "git", "-C", M.root, "check-ignore", "--stdin" }, { stdin = table.concat(paths, "\n") .. "\n", text = true })
    :wait()
  local ignored = {}
  if result.code == 0 then
    for line in result.stdout:gmatch("[^\n]+") do
      ignored[line] = true
    end
  end
  return ignored
end

local function buffers_by_path()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_file_buffer(buf) then
      buffers[real_path(vim.api.nvim_buf_get_name(buf))] = buf
    end
  end
  return buffers
end

local function follow(changed)
  if #changed == 0 then
    return
  end
  if #changed > max_files_to_follow then
    vim.notify(("%d arquivos mudaram em %s"):format(#changed, vim.fs.basename(M.root)))
    return
  end

  local latest = changed[#changed]
  if not M.enabled or user_is_busy() then
    vim.notify(("%s mudou"):format(display_path(latest.path)))
    return
  end

  local buf, ranges = latest.buf, latest.ranges
  if not buf then
    buf = vim.fn.bufadd(latest.path)
    vim.fn.bufload(buf)
    vim.bo[buf].buflisted = true
    ranges = uncommitted_ranges(latest.path)
    highlight(buf, ranges)
  end
  reveal(buf, ranges[1] and ranges[1].first or 1)
end

local function track_change(path, buf, changed)
  if not buf then
    changed[#changed + 1] = { path = path }
    return
  end
  if vim.bo[buf].modified then
    vim.notify(
      ("%s mudou em disco, mas você tem mudanças não salvas nesse arquivo"):format(display_path(path)),
      vim.log.levels.WARN
    )
    return
  end
  local ranges = reload(buf)
  if ranges and #ranges > 0 then
    highlight(buf, ranges)
    changed[#changed + 1] = { path = path, buf = buf, ranges = ranges }
  end
end

local function process(paths)
  local ignored = ignored_by_git(paths)
  local buffers = buffers_by_path()
  local changed = {}
  for _, path in ipairs(paths) do
    if not ignored[path] then
      track_change(path, buffers[path], changed)
    end
  end
  follow(changed)
end

local function file_version(stat)
  return ("%d.%d:%d"):format(stat.mtime.sec, stat.mtime.nsec, stat.size)
end

local function written_by_nvim(path, stat)
  return recent_writes[path] == file_version(stat)
end

local function flush()
  local queued = {}
  for path, order in pairs(pending) do
    queued[#queued + 1] = { path = path, order = order }
  end
  pending = {}
  table.sort(queued, function(a, b)
    return a.order < b.order
  end)

  local paths = {}
  for _, item in ipairs(queued) do
    local stat = vim.uv.fs_stat(item.path)
    if stat and stat.type == "file" and not written_by_nvim(item.path, stat) then
      paths[#paths + 1] = item.path
    end
  end
  if #paths == 0 or not M.root then
    return
  end
  local ok, err = pcall(process, paths)
  if not ok then
    vim.notify("workspace.follow: " .. tostring(err), vim.log.levels.ERROR)
  end
end

local function on_event(err, filename)
  if err or not filename or not M.root or in_skipped_dir(filename) then
    return
  end
  sequence = sequence + 1
  pending[M.root .. "/" .. filename] = sequence
  debounce_timer:stop()
  debounce_timer:start(debounce_ms, 0, vim.schedule_wrap(flush))
end

function M.unwatch()
  if watcher then
    watcher:stop()
    watcher:close()
    watcher = nil
  end
  M.root = nil
  pending = {}
end

function M.watch()
  local root = require("workspace.root").get()
  if root == M.root then
    return
  end
  M.unwatch()
  if not root then
    return
  end
  M.root = root
  debounce_timer = debounce_timer or vim.uv.new_timer()
  watcher = vim.uv.new_fs_event()
  watcher:start(root, { recursive = true }, on_event)
end

function M.toggle()
  M.enabled = not M.enabled
  vim.notify("Seguir mudanças no worktree " .. (M.enabled and "ligado" or "desligado"))
end

function M.setup()
  local group = vim.api.nvim_create_augroup("workspace_follow", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(event)
      local path = real_path(vim.api.nvim_buf_get_name(event.buf))
      local stat = vim.uv.fs_stat(path)
      recent_writes[path] = stat and file_version(stat) or nil
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.unwatch })
  M.watch()
end

return M
