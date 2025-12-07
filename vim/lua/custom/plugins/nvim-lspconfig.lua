return {
  'neovim/nvim-lspconfig',
  config = function()
    vim.lsp.config("clangd", {
      autostart = true,
      cmd = { 'clangd', '--background-index=false', '--clang-tidy', '-j=8' },
      filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "arduino" },
      capabilities = {
        textDocument = {
          semanticTokens = {
            multilineTokenSupport = true,
          }
        }
      }
    })

    --- lua_ls -------------------------------------------------------
    ------------------------------------------------------------------

    local lua_runtime_path = vim.split(package.path, ';')
    table.insert(lua_runtime_path, "lua/?.lua")
    table.insert(lua_runtime_path, "lua/?/init.lua")

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
            path = lua_runtime_path,
          },
          diagnostics = {
            globals = { 'vim', 'ngx' },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })

    --- gopls -------------------------------------------------------
    -----------------------------------------------------------------

    vim.lsp.config("gopls", {
      settings = {
        gopls = {
          buildFlags = { "-tags=goexperiment.arenas" },
          analyses = {
            shadow = true,
          },
          staticcheck = true,
          gofumpt = true,
          codelenses = {
            gc_details = true
          },
        },
      }
    })

    --- rust-analyzer -----------------------------------------------
    -----------------------------------------------------------------

    vim.lsp.config("rust_analyzer", {
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

    vim.diagnostic.config({
      virtual_text = true,
      signs = false,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    local servers = {
      "clangd",
      "lua_ls",
      "gopls",
      "rust_analyzer",
      "pyright",
      "ts_ls",
      "dartls",
      "zls",
      "svelte",
      "sourcekit"
    }

    for _, lsp in ipairs(servers) do
      vim.lsp.enable(lsp)
    end


    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
    vim.keymap.set('n', ']d', function()
      vim.diagnostic.jump({ count = 1, float = true })
    end)
    vim.keymap.set('n', '[d', function()
      vim.diagnostic.jump({ count = -1, float = true })
    end)

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

        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client ~= nil and client:supports_method('textDocument/completion') then
          vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
        end
      end,
    })
  end
}
