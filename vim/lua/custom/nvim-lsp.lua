local nvim_lsp = require('lspconfig')
local null_ls = require("null-ls")
local h = require("null-ls.helpers")
local arc = require("custom.arc")
local uservices = require("custom.uservices")
local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})



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

local on_attach = function(_, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = 0 })
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = 0 })
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = 0 })
  vim.keymap.set("n", "gr", vim.lsp.buf.references)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setqflist)
  vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
  vim.keymap.set("n", "<leader>H", vim.diagnostic.goto_prev)
  vim.keymap.set("n", "<leader>L", vim.diagnostic.goto_next)

  local filetype = vim.bo.filetype
  if filetype == "go" then
    vim.keymap.set("n", "<leader>E", function()
      -- TODO(nk2ge5k): add error check
      vim.lsp.buf_request_sync(bufnr, "workspace/executeCommand", {
        command = "gopls.gc_details",
        arguments = { vim.uri_from_bufnr(bufnr) },
      }, 2000)
    end)
  end
end

--- clangd -------------------------------------------------------
------------------------------------------------------------------

local clangd_command = function()
  local cmd = {
    'clangd',
    '--background-index=false',
    '--clang-tidy',
    '-j=8',
  }

  local cwd = vim.fn.getcwd()

  if not arc.owns(cwd) then
    return cmd
  end
  local uservices_root = arc.root() .. "/taxi/uservices"
  if not startswith(cwd, uservices_root) then
    return cmd
  end

  local user = vim.fn.getenv("USER")

  if vim.loop.os_uname().sysname == "Darwin" then
    cmd[#cmd + 1] = "--compile-commands-dir=" .. uservices_root
  else
    if is_file_exists(cwd .. "/ya.make.ext") then
      cmd[#cmd + 1] = "--compile-commands-dir=/tmp/" .. user .. "/ya-dump"
    elseif is_file_exists(cwd .. "/service.yaml") then
      cmd[#cmd + 1] = "--compile-commands-dir=/tmp/" .. user .. "/uservices-build/build"
    end
  end

  return cmd
end

local clangd_should_autostart = function()
  local name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  if name == "eats-catalog" then
    return false
  end
  return true
end

local setup_clangd = function(lsp)
  lsp.clangd.setup {
    autostart = clangd_should_autostart(),
    on_attach = on_attach,
    cmd = clangd_command(),
  }
end

--- lua_ls -------------------------------------------------------
------------------------------------------------------------------

local setup_lua = function(lsp)
  local runtime_path = vim.split(package.path, ';')
  table.insert(runtime_path, "lua/?.lua")
  table.insert(runtime_path, "lua/?/init.lua")

  lsp.lua_ls.setup {
    on_attach = on_attach,
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
    on_attach = on_attach,
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          unusedvariable = true,
          fieldalignment = true,
          nilness = true,
          shadow = true,
        },
        staticcheck = true,
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
    on_attach = on_attach,
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

--- null-ls -----------------------------------------------------
-----------------------------------------------------------------

local inside_uservices = uservices.is_uservices_directory(vim.fn.getcwd())

local _insert = function(dst, ...)
  local args = { n = select("#", ...), ... }
  for _, val in ipairs(args) do
    table.insert(dst, val)
  end
end

if vim.fn.executable("ya") == 1 and inside_uservices then
  null_ls.register({
    method = null_ls.methods.FORMATTING,
    filetypes = { "python", "cpp" },
    generator = h.formatter_factory({
      command = "ya",
      args = { "tool", "tt", "format", "$FILENAME" },
      runtime_codition = inside_uservices,
      timeout = 20000,
      multiple_files = false,
      async = true,
    })
  })
end

local sources = {
  null_ls.builtins.completion.spell,
  null_ls.builtins.diagnostics.shellcheck,
  null_ls.builtins.code_actions.shellcheck,
}

if not inside_uservices then
  _insert(sources,
    null_ls.builtins.formatting.isort,
    null_ls.builtins.formatting.black.with { extra_args = { "--fast" } })
end


null_ls.setup({ sources = sources })


local servers = { "pyright", "tsserver", "dartls", "kotlin_language_server" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = on_attach }
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

vim.diagnostic.config({
  virtual_text = true,
  signs = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
