return {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-mini/mini.nvim',
      'nvim-mini/mini.icons'
    },
    opts = {},
    config = function()
      require("render-markdown").setup({
        latex = { enabled = false },
      })
    end
}
