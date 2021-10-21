require'nvim-treesitter.configs'.setup {
    ensure_installed = "maintained",
    ignore_install = {},
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
        },
    },
    highlight = {
        enable = true,
        disable = {},
        additional_vim_regex_highlighting = false
    },
}
