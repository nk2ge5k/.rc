return {
  "fatih/vim-go",
  build = ':GoInstallBinaries',
  config = function()
    vim.g.go_term_mode = "split"
    vim.g.go_fmt_command = "gofmt"
    vim.g.go_imports_mode = "goimports"
    vim.g.go_def_mode = "godef"
    vim.g.go_rename_command = "gorename"
    vim.g.go_gopls_enabled = 0
  end
}
