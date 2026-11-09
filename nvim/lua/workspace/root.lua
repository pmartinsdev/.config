local M = {}

local current

function M.real_path(path)
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

function M.is_inside(path, root)
  return path == root or vim.startswith(path, root .. "/")
end

function M.refresh()
  local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { cwd = vim.fn.getcwd(), text = true }):wait()
  current = result.code == 0 and M.real_path(vim.trim(result.stdout)) or nil
  return current
end

function M.get()
  return current
end

function M.key()
  return current or M.real_path(vim.fn.getcwd())
end

return M
