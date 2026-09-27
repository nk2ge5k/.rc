if vim.g.loaded_gopkg then
  return
end
vim.g.loaded_gopkg = true

local subcommands = {
  search = function(args)
    require("gopkg").search(table.concat(args, " "))
  end,
  symbol = function(args)
    require("gopkg").search_symbol(args[1])
  end,
  doc = function(args)
    if not args[1] then
      return vim.notify("gopkg: usage: :GoPkg doc <package>[@version][.Symbol]", vim.log.levels.WARN)
    end
    require("gopkg").open(args[1], args[2])
  end,
  symbols = function(args)
    require("gopkg").symbols(args[1])
  end,
  cursor = function()
    require("gopkg").cursor()
  end,
}

vim.api.nvim_create_user_command("GoPkg", function(opts)
  local args = opts.fargs
  local sub = table.remove(args, 1)
  if not sub then
    return require("gopkg").search()
  end
  local fn = subcommands[sub]
  if not fn then
    -- `:GoPkg net/http` is a shortcut for `:GoPkg doc net/http`.
    return require("gopkg").open(sub, args[1])
  end
  fn(args)
end, {
  nargs = "*",
  desc = "Search and browse Go package docs (pkgsite-cli)",
  complete = function(arglead, cmdline)
    local n = #vim.split(vim.trim(cmdline), "%s+")
    if n > 2 or (n == 2 and arglead == "") then
      return {}
    end
    return vim.tbl_filter(function(s)
      return vim.startswith(s, arglead)
    end, vim.tbl_keys(subcommands))
  end,
})

vim.keymap.set("n", "<Plug>(gopkg-cursor)", function()
  require("gopkg").cursor()
end, { desc = "gopkg: docs for identifier under cursor" })
vim.keymap.set("n", "<Plug>(gopkg-search)", function()
  require("gopkg").search()
end, { desc = "gopkg: search packages" })
