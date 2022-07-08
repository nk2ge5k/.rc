local nvim_lsp = require('lspconfig')


local is_file_exists = function(file_name)
  local file = io.open(file_name, "r")

  if file == nil then
    return false
  end

  return true
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
end

--- clangd -------------------------------------------------------
------------------------------------------------------------------

local clangd_command = function()
  local cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '-j=8',
  }

  local cwd = vim.fn.getcwd()
  local user = vim.fn.getenv("USER")

  if is_file_exists(cwd .. "/ya.make.ext") then
    cmd[#cmd + 1] = "--compile-commands-dir=/tmp/" .. user .. "/ya-dump"
  elseif is_file_exists(cwd .. "/service.yaml") then
    cmd[#cmd + 1] = "--compile-commands-dir=/tmp/" .. user .. "/uservices-build/build"
  end

  return cmd
end


local setup_clangd = function(lsp)
  lsp.clangd.setup { on_attach = on_attach, cmd = clangd_command() }
end

--- sumneko_lua --------------------------------------------------
------------------------------------------------------------------

local setup_lua = function(lsp)
  local runtime_path = vim.split(package.path, ';')
  table.insert(runtime_path, "lua/?.lua")
  table.insert(runtime_path, "lua/?/init.lua")

  nvim_lsp.sumneko_lua.setup {
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

local servers = { "gopls", "rls" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = on_attach }
end

setup_clangd(nvim_lsp)
setup_lua(nvim_lsp)

vim.diagnostic.config({
  virtual_text = true,
  signs = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
