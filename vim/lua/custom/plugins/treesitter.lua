return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = 'main',
    build = ':TSUpdate',
    opts_extend = { "ensure_installed" },
    opts = {
      indent = { enable = true },
      highlight = { enable = true },
      folds = { enable = false },
      ensure_installed = {
        "yaml",
        "html",
        "vimdoc",
        "markdown",
        "markdown_inline",
        "javascript",
        "typescript",
        "c",
        "lua",
        "rust",
        "jsdoc",
        "bash",
        "go",
        "kotlin",
        "java"
      },
    },
  }
}
