local nvim_lsp = require('lspconfig')

local is_file_exists = function(file_name)
  local file = io.open(file_name, "r")

  if file == nil then
    return false
  end

  return true
end

local startswith = function(text, prefix)
  return text:find(prefix, 1, true) == 1
end

--- clangd -------------------------------------------------------
------------------------------------------------------------------

local clangd_command = function()
  return {
    'clangd',
    '--background-index=false',
    '--clang-tidy',
    '-j=8',
  }
end

local setup_clangd = function(lsp)
  lsp.clangd.setup {
    autostart = true,
    cmd = clangd_command(),
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "arduino" }
  }
end

--- lua_ls -------------------------------------------------------
------------------------------------------------------------------

local setup_lua = function(lsp)
  local runtime_path = vim.split(package.path, ';')
  table.insert(runtime_path, "lua/?.lua")
  table.insert(runtime_path, "lua/?/init.lua")

  lsp.lua_ls.setup {
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = 'LuaJIT',
          -- Setup your lua path
          path = runtime_path,
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = { 'vim', 'ngx' },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false,
        },
      },
    },
  }
end

--- gopls -------------------------------------------------------
-----------------------------------------------------------------

local setup_gopls = function(lsp)
  lsp.gopls.setup {
    settings = {
      gopls = {
        buildFlags = { "-tags=goexperiment.arenas" },
        analyses = {
          unusedparams = true,
          unusedvariable = true,
          fieldalignment = true,
          nilness = true,
          shadow = true,
        },
        staticcheck = true,
        gofumpt = true,
        codelenses = {
          gc_details = true
        },
      },
    }
  }
end

--- rust-analyzer -----------------------------------------------
-----------------------------------------------------------------

local setup_rust_analyzer = function(lsp)
  lsp.rust_analyzer.setup({
    settings = {
      ["rust-analyzer"] = {
        imports = {
          granularity = {
            group = "module",
          },
          prefix = "self",
        },
        cargo = {
          buildScripts = {
            enable = true,
          },
        },
        procMacro = {
          enable = true
        },
      }
    }
  })
end


vim.diagnostic.config({
  virtual_text = true,
  signs = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

local servers = {
  "pyright",
  "tsserver",
  "dartls",
  "kotlin_language_server",
  "zls",
}

for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {}
end

local custom = {
  -- clangd
  setup_clangd,
  -- lua_ls
  setup_lua,
  -- gopls
  setup_gopls,
  -- rust_analyzer
  setup_rust_analyzer,
}
for _, fn in ipairs(custom) do
  fn(nvim_lsp)
end

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})
