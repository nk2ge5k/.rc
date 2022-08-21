local nvim_lsp = require('lspconfig')
local arc = require("custom.arc")


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
    '--background-index',
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

  lsp.sumneko_lua.setup {
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

local servers = { "rls", "pyright", "tsserver" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = on_attach }
end

setup_clangd(nvim_lsp)
setup_lua(nvim_lsp)
setup_gopls(nvim_lsp)

vim.diagnostic.config({
  virtual_text = true,
  signs = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
