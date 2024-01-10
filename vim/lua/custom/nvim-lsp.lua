local nvim_lsp = require('lspconfig')
local arc = require("custom.arc")
local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
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
    ['<C-u>'] = cmp.mapping.abort(),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    {
      name = 'buffer',
      option = {
        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            bufs[vim.api.nvim_win_get_buf(win)] = true
          end
          return vim.tbl_keys(bufs)
        end,
      },
    },
    { name = 'luasnip' },
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
  vim.keymap.set("n", "gv", vim.lsp.buf.definition, { buffer = 0 })
  vim.keymap.set('n', '<leader>v', ':vsplit | lua vim.lsp.buf.definition()<CR>')
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = 0 })
  vim.keymap.set("n", "gr", vim.lsp.buf.references)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
  vim.keymap.set("n", "ga", vim.lsp.buf.code_action)
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setqflist)
  vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
  vim.keymap.set("n", "<leader>H", vim.diagnostic.goto_prev)
  vim.keymap.set("n", "<leader>L", vim.diagnostic.goto_next)

  local filetype = vim.bo.filetype
  if filetype == "go" then
    vim.keymap.set("n", "<leader>E", function()
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

  if vim.uv.os_uname().sysname == "Darwin" then
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
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }
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

local servers = {
  "pyright",
  "tsserver",
  "dartls",
  "kotlin_language_server",
  "zls",
  "bufls"
}

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
