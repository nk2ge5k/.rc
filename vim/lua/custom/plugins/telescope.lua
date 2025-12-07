return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    'nvim-telescope/telescope-ui-select.nvim',
  },
  config = function()
    local telescope = require('telescope')
    local builtin = require('telescope.builtin')
    local actions = require('telescope.actions')

    telescope.setup({
      defaults = {
        file_ignore_patterns = { 'node_modules', 'vendor' },
        mappings = {
          i = {
            ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
          },
          n = {
            ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
          }
        },
      },
      extensions = {
        fzf = {},
        ['ui-select'] = {
          require('telescope.themes').get_dropdown {},
        },
      }
    })

    pcall(telescope.load_extension, 'fzf')
    pcall(telescope.load_extension, 'ui-select')

    local opts = require('telescope.themes').get_ivy({
      layout_config = { height = 40 },
      border = true,
    })

    vim.keymap.set('n', '<leader>fh', function()
      builtin.help_tags(opts)
    end)
    vim.keymap.set('n', '<C-p>', function()
      builtin.find_files(opts)
    end)
    vim.keymap.set('n', '<C-f>', function()
      builtin.current_buffer_fuzzy_find(opts)
    end)
    vim.keymap.set('n', '<leader>,', function()
      builtin.live_grep(opts)
    end)
    vim.keymap.set('n', '<leader>;', function()
      builtin.buffers(opts)
    end)
    vim.keymap.set('n', '<leader>dl', function()
      builtin.diagnostics(opts)
    end)
    vim.keymap.set({ 'n', 'v' }, '<leader>fw', function()
      builtin.grep_string(opts)
    end)
  end
}
