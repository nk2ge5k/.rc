return {
  "fatih/vim-go",
  build = ':GoInstallBinaries',
  config = function()
    vim.g.go_term_mode = "split"
  end
}
