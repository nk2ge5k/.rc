local cli = require("gopkg.cli")
local config = require("gopkg.config")
local parse = require("gopkg.parse")
local view = require("gopkg.view")

local M = {}

local notify = view.notify

---@param opts gopkg.Config?
function M.setup(opts)
  config.setup(opts)
end

--- Open documentation for a package, optionally jumping to a symbol.
---@param pkg string package path, optionally with @version
---@param symbol string|false|nil symbol to jump to; nil parses it from `pkg`, false disables that
function M.open(pkg, symbol)
  if symbol == nil then
    pkg, symbol = parse.split_target(pkg)
  end
  symbol = symbol or nil
  notify("loading " .. pkg .. " …")
  cli.package(pkg, function(err, res)
    if err then
      return notify(("%s: %s"):format(pkg, err), vim.log.levels.ERROR)
    end
    view.show(res, symbol)
  end)
end

local function pick_result(items, title, on_choice)
  if #items == 0 then
    return notify("no results for " .. title, vim.log.levels.WARN)
  end
  vim.ui.select(items, {
    prompt = title,
    format_item = function(it)
      local s = it.packagePath
      if it.version and it.version ~= "" then
        s = s .. "  " .. it.version
      end
      if it.synopsis and it.synopsis ~= "" then
        s = s .. " — " .. it.synopsis
      end
      return s
    end,
  }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

--- Search packages and open the selected one.
---@param query string?
function M.search(query)
  if not query or query == "" then
    vim.ui.input({ prompt = "Search Go packages: " }, function(input)
      if input and input ~= "" then
        M.search(input)
      end
    end)
    return
  end
  notify("searching " .. query .. " …")
  cli.search(query, nil, function(err, items)
    if err then
      return notify(err, vim.log.levels.ERROR)
    end
    pick_result(items, "pkg.go.dev: " .. query, function(it)
      M.open(it.packagePath .. "@" .. it.version, false)
    end)
  end)
end

--- Search packages exporting `symbol` and open the selected one at it.
--- pkg.go.dev matches the query itself against symbol names, so the symbol is
--- used as both the query and the -symbol filter.
---@param symbol string?
function M.search_symbol(symbol)
  if not symbol or symbol == "" then
    vim.ui.input({ prompt = "Go symbol: " }, function(input)
      if input and input ~= "" then
        M.search_symbol(input)
      end
    end)
    return
  end
  notify("searching symbol " .. symbol .. " …")
  cli.search(symbol, symbol, function(err, items)
    if err then
      return notify(err, vim.log.levels.ERROR)
    end
    pick_result(items, ("pkg.go.dev: symbol %s"):format(symbol), function(it)
      M.open(it.packagePath .. "@" .. it.version, symbol)
    end)
  end)
end

--- Pick a symbol of `pkg` (or of the current doc buffer).
---@param pkg string?
function M.symbols(pkg)
  local buf = vim.api.nvim_get_current_buf()
  if (not pkg or pkg == "") and view.state[buf] then
    return view.pick_symbol(buf)
  end
  if not pkg or pkg == "" then
    return notify("usage: :GoPkg symbols <package>", vim.log.levels.WARN)
  end
  cli.package(pkg, function(err, res)
    if err then
      return notify(("%s: %s"):format(pkg, err), vim.log.levels.ERROR)
    end
    view.show(res)
    view.pick_symbol(vim.api.nvim_get_current_buf())
  end)
end

--- Open docs for the Go identifier (or import path) under cursor.
function M.cursor()
  local target, symbol = require("gopkg.cursor").resolve()
  if not target then
    return notify(symbol or "nothing to look up under cursor", vim.log.levels.WARN)
  end
  M.open(target, symbol or false)
end

return M
