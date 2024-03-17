local notify = require("notify")

notify.setup({
  icons = {
    DEBUG = "DEBUG",
    ERROR = "ERROR",
    INFO = "INFO",
    TRACE = "TRACE",
    WARN = "WARN"
  },
  stages = "static",
  timeout = 4000,
})

-- Setup notifications engine
vim.notify = notify

local version = vim.version()
if version.major >= 0 and version.minor >= 8 then
  -- Set command line height to zero on versions >=0.8.x
  vim.o.ch = 0
end

-- Copilot

vim.keymap.set('i', '<C-y>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false
})

vim.g.copilot_no_tab_map = true

require("custom.keymaps")
require("custom.nvim-lsp")
require("custom.luasnip")
require("custom.comment")
require("custom.scratch")
require("custom.tmux")
