require("configs.keymaps")
require("configs.options")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local function load_plugins()
  local plugins = {}
  local plugin_files = vim.fn.glob(vim.fn.stdpath("config") .. "/lua/plugins/*.lua", true, true)
  for _, file in ipairs(plugin_files) do
    local plugin = dofile(file)
    table.insert(plugins, plugin)
  end
  return plugins
end

require("lazy").setup(load_plugins())
