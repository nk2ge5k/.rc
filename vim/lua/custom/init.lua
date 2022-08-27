local notify = require("notify")
local static = require("notify.stages.static")

notify.setup({
  stages = static,
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
