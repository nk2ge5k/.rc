local notify = require("notify")

notify.setup({
  stages = require("notify.stages.static"),
  icons = {},
  timeout = 4000,
})

-- Setup notification engine
vim.notify = notify

local version = vim.version()
if version.major >= 0 and version.minor >= 8 then
  -- Set command line height to zero on verions >=0.8.x
  vim.o.ch = 0
end

require("custom.keymaps")
require("custom.nvim-lsp")
require("custom.treesitter")
require("custom.luasnip")
require("custom.comment")
require("custom.scratch")
require("custom.tmux")
require("custom.uservices")
