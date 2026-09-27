-- Thin async wrapper around pkgsite-cli.
local config = require("gopkg.config")

local M = {}

---@type table<string, any>
local cache = {}

local function common_flags(args)
  local o = config.options
  if o.server then
    vim.list_extend(args, { "-server", o.server })
  end
  if o.timeout then
    vim.list_extend(args, { "-timeout", o.timeout })
  end
  return args
end

local function error_message(res)
  local ok, decoded = pcall(vim.json.decode, res.stdout or "")
  if ok and type(decoded) == "table" and decoded.message then
    return ("%s (%s)"):format(decoded.message, decoded.code or "?")
  end
  local msg = vim.trim(res.stderr or "")
  if msg == "" then
    msg = vim.trim(res.stdout or "")
  end
  -- Keep only the first line; pkgsite-cli prints full usage after errors.
  return (msg:match("^[^\n]*")) or ("exit code " .. tostring(res.code))
end

--- Run pkgsite-cli with the given subcommand, flags and positional args.
--- Output is decoded as JSON and passed to `cb(err, result)` on the main loop.
---@param sub string
---@param flags string[]
---@param positional string[]
---@param cb fun(err: string?, result: table?)
function M.run(sub, flags, positional, cb)
  local cmd = { config.options.cmd, sub, "-json" }
  vim.list_extend(cmd, common_flags(vim.deepcopy(flags)))
  vim.list_extend(cmd, positional)

  local key = table.concat(cmd, "\0")
  if cache[key] then
    cb(nil, cache[key])
    return
  end

  local ok, err = pcall(vim.system, cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        cb(error_message(res))
        return
      end
      local dok, decoded = pcall(vim.json.decode, res.stdout, { luanil = { object = true, array = true } })
      if not dok or type(decoded) ~= "table" then
        cb("failed to decode pkgsite-cli output")
        return
      end
      cache[key] = decoded
      cb(nil, decoded)
    end)
  end)
  if not ok then
    cb(("cannot run %q: %s"):format(config.options.cmd, err))
  end
end

---@class gopkg.SearchResult
---@field packagePath string
---@field modulePath string
---@field version string
---@field synopsis string

---@param query string
---@param symbol string?
---@param cb fun(err: string?, items: gopkg.SearchResult[]?)
function M.search(query, symbol, cb)
  local flags = { "-limit", tostring(config.options.limit) }
  if symbol and symbol ~= "" then
    vim.list_extend(flags, { "-symbol", symbol })
  end
  M.run("search", flags, { query }, function(err, res)
    if err then
      return cb(err)
    end
    cb(nil, res.items or {})
  end)
end

---@class gopkg.Package
---@field path string
---@field name string
---@field synopsis string
---@field modulePath string
---@field version string
---@field isLatest boolean
---@field isStandardLibrary boolean
---@field goos string
---@field goarch string
---@field docs string

--- Fetch package metadata and rendered markdown docs.
---@param pkg string package path, optionally with @version
---@param cb fun(err: string?, pkg: gopkg.Package?)
function M.package(pkg, cb)
  local o = config.options
  local flags = { "-doc", "md" }
  if o.examples then
    table.insert(flags, "-examples")
  end
  if o.goos then
    vim.list_extend(flags, { "-goos", o.goos })
  end
  if o.goarch then
    vim.list_extend(flags, { "-goarch", o.goarch })
  end
  M.run("package", flags, { pkg }, function(err, res)
    if err then
      return cb(err)
    end
    if not res.package then
      return cb("no package in response")
    end
    cb(nil, res.package)
  end)
end

function M.clear_cache()
  cache = {}
end

return M
