local notify = require("notify")
require("fidget").setup {}

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

local do_did_done = vim.api.nvim_create_augroup("DoDidDone", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(args)
    local dir  = vim.fn.getcwd()
    local home = vim.fn.expand('$HOME')

    if dir == home and (args.file == nil or args.file == "") then
      vim.cmd('e ' .. '~/dodidone.txt')
    end
  end,
  group = do_did_done,
})

require 'colorizer'.setup {
  '*'; -- Highlight all files, but customize some others.
}

require("zk").setup({
  -- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
  -- or select" (`vim.ui.select`). It's recommended to use "telescope",
  -- "fzf", "fzf_lua", "minipick", or "snacks_picker".
  picker = "telescope",

  lsp = {
    -- `config` is passed to `vim.lsp.start_client(config)`
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
      -- on_attach = ...
      -- etc, see `:h vim.lsp.start_client()`
    },

    -- automatically attach buffers in a zk notebook that match the given filetypes
    auto_attach = {
      enabled = true,
      filetypes = { "markdown" },
    },
  },
})

require("custom.keymaps")
require("custom.nvim-lsp")
require("custom.luasnip")
require("custom.comment")
require("custom.scratch")
require("custom.tmux")
