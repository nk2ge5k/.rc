local home_dir = os.getenv("HOME")
package.path = home_dir .. "/.rc/vim/lua/?.lua;" .. package.path

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath })
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  spec  = { import = 'custom/plugins' },
  change_detection = { notify = false },
})

require("custom.c")
