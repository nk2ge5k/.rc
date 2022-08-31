local notify = require("notify")

notify.setup({
  stages = require("notify.stages.static"),
  icons = {},
  timeout = 4000,
})

vim.notify = notify

require("custom.keymaps")
require("custom.nvim-lsp")
require("custom.treesitter")
require("custom.luasnip")
require("custom.comment")
require("custom.scratch")
require("custom.tmux")
require("custom.uservices")
