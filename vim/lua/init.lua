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

-- matchadd-based comment annotation highlights (works with treesitter)
vim.api.nvim_create_autocmd({"BufWinEnter"}, {
  callback = function()
    vim.fn.matchadd("@comment.attodo",    "@todo")
    vim.fn.matchadd("@comment.atnote",    "@note")
    vim.fn.matchadd("@comment.atnote",    "@question")
    vim.fn.matchadd("@comment.aterror",   "@fix")
    vim.fn.matchadd("@comment.aterror",   "@leak")
    vim.fn.matchadd("@comment.aterror",   "@slow")
    vim.fn.matchadd("@comment.important", "@important")
    vim.fn.matchadd("@comment.hack",      "@hack")
    vim.fn.matchadd("@comment.nocheckin", "@nocheckin")
  end,
})
