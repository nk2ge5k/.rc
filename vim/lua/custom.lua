local notify = require("notify")
local null_ls = require("null-ls")

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

require("fidget").setup {}

null_ls.setup({
  sources = {
    null_ls.builtins.completion.spell,
    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.code_actions.shellcheck,
    -- python
    null_ls.builtins.formatting.black.with { extra_args = { "--fast" } },
    null_ls.builtins.formatting.isort,
  },
})

require("custom.keymaps")
require("custom.nvim-lsp")
require("custom.treesitter")
require("custom.luasnip")
require("custom.comment")
require("custom.scratch")
require("custom.tmux")
require("custom.uservices")
