-- Pure helpers for parsing pkgsite markdown docs and user input.
local M = {}

---@class gopkg.Symbol
---@field name string   e.g. "Builder", "Builder.Grow", "Client.Timeout"
---@field kind "func"|"method"|"type"|"field"|"const"|"var"
---@field lnum integer  1-based line in the rendered buffer
---@field text string   declaration line
---@field top boolean   true for top-level declarations (not fields)

local function ident(s)
  return s and s:match("^[%a_][%w_]*$") ~= nil
end

local function exported(s)
  return s and s:match("^%u") ~= nil
end

--- Build a symbol index from rendered markdown lines.
--- Every declaration lives in a ```go fenced block; the first line of the
--- block is the declaration signature.
---@param lines string[]
---@return gopkg.Symbol[] symbols in buffer order
---@return table<string, gopkg.Symbol> by_name
function M.index(lines)
  local symbols, by_name = {}, {}

  local function add(name, kind, lnum, top)
    if by_name[name] then
      return
    end
    local sym = { name = name, kind = kind, lnum = lnum, text = vim.trim(lines[lnum]), top = top }
    table.insert(symbols, sym)
    by_name[name] = sym
  end

  local i, n = 1, #lines
  while i <= n do
    if lines[i]:match("^```go%s*$") then
      local first = i + 1
      local close = first
      while close <= n and not lines[close]:match("^```%s*$") do
        close = close + 1
      end
      local decl = lines[first] or ""

      local recv, mname = decl:match("^func %(([^)]*)%) ([%a_][%w_]*)")
      -- "b *Builder", "Header", "s *Set[T]" -> receiver type name
      recv = recv and recv:gsub("%[.*%]", ""):match("([%a_][%w_]*)%s*$")
      if recv then
        add(recv .. "." .. mname, "method", first, true)
      else
        local fname = decl:match("^func ([%a_][%w_]*)")
        if fname then
          add(fname, "func", first, true)
        end
      end

      local tname = decl:match("^type ([%a_][%w_]*)")
      if tname then
        add(tname, "type", first, true)
        -- struct fields / interface methods, indented by exactly one tab
        for l = first + 1, close - 1 do
          local member = lines[l]:match("^\t([%a_][%w_]*)")
          if member and exported(member) then
            add(tname .. "." .. member, "field", l, false)
          end
        end
      elseif decl:match("^type %($") then
        for l = first + 1, close - 1 do
          local name = lines[l]:match("^\t([%a_][%w_]*)")
          if exported(name) then
            add(name, "type", l, true)
          end
        end
      end

      local vkind, rest = decl:match("^(%l+) (.*)$")
      if vkind == "const" or vkind == "var" then
        if rest == "(" then
          for l = first + 1, close - 1 do
            local name = lines[l]:match("^\t([%a_][%w_]*)")
            if exported(name) then
              add(name, vkind, l, true)
            end
          end
        else
          -- `const A, B = ...` or `var X Type`
          local names = rest:match("^([%w_, ]-)%s*[=%s]") or rest
          for name in names:gmatch("[%a_][%w_]*") do
            if exported(name) then
              add(name, vkind, first, true)
            end
          end
        end
      end

      i = close + 1
    else
      i = i + 1
    end
  end
  return symbols, by_name
end

--- Split "net/http.Client.Do", "gopkg.in/yaml.v3@v3.0.1#Node" etc.
--- into package (with optional @version) and symbol.
---@param arg string
---@return string pkg
---@return string? symbol
function M.split_target(arg)
  local pkg, sym = arg:match("^(.-)#(.*)$")
  if pkg then
    return pkg, sym ~= "" and sym or nil
  end
  -- The symbol can only live in the last path element.
  local dir, last = arg:match("^(.*/)([^/]*)$")
  if not dir then
    dir, last = "", arg
  end
  local s = last:find("%.%u")
  if s then
    return dir .. last:sub(1, s - 1), last:sub(s + 1)
  end
  return arg, nil
end

---@class gopkg.Link
---@field text string
---@field target string
---@field col_start integer 1-based
---@field col_end integer 1-based inclusive

--- Find the markdown link at (1-based) column `col` in `line`.
---@return gopkg.Link?
function M.link_at(line, col)
  local init = 1
  while true do
    local s, e, text, target = line:find("%[(.-)%]%(([^)]*)%)", init)
    if not s then
      return nil
    end
    if col >= s and col <= e then
      return { text = text, target = target, col_start = s, col_end = e }
    end
    init = e + 1
  end
end

--- Classify a link target.
---@param target string
---@return { kind: "anchor"|"package"|"url", pkg: string?, anchor: string?, url: string? }
function M.classify_link(target)
  if target:match("^%a[%w+.-]*://") then
    return { kind = "url", url = target }
  end
  if target:sub(1, 1) == "#" then
    return { kind = "anchor", anchor = target:sub(2) }
  end
  local path = target:gsub("^/", "")
  local pkg, anchor = path:match("^(.-)#(.*)$")
  pkg = pkg or path
  return { kind = "package", pkg = pkg, anchor = anchor ~= "" and anchor or nil }
end

--- Guess the default import name for an import path.
---@param path string
---@return string[] candidates, most likely first
function M.import_names(path)
  local parts = vim.split(path, "/", { plain = true })
  local last = parts[#parts]
  if last:match("^v%d+$") and #parts > 1 then
    last = parts[#parts - 1]
  end
  local names = {}
  local function add(n)
    if n and n ~= "" and ident(n) and not vim.tbl_contains(names, n) then
      table.insert(names, n)
    end
  end
  last = last:gsub("%.v%d+$", "") -- gopkg.in/yaml.v3
  add(last)
  local stripped = last:gsub("^go[-.]", ""):gsub("[-.]go$", "")
  add(stripped)
  add((stripped:gsub("[-.]", "_")))
  add((stripped:gsub("[-.]", "")))
  local tail = stripped:match("[-.]([%w_]+)$")
  add(tail)
  return names
end

--- Parse import declarations of a Go source buffer.
---@param lines string[]
---@return { alias: string?, path: string }[]
function M.imports(lines)
  local result = {}
  local function spec(s)
    local alias, path = s:match('^%s*([%w_%.]+)%s+"([^"]+)"')
    if not path then
      path = s:match('^%s*"([^"]+)"')
    end
    if path then
      table.insert(result, { alias = alias, path = path })
    end
  end
  local in_block = false
  for _, line in ipairs(lines) do
    line = line:gsub("//.*$", "")
    if in_block then
      if line:match("^%s*%)") then
        in_block = false
      else
        spec(line)
      end
    elseif line:match("^import%s*%(") then
      in_block = true
      spec(line:match("^import%s*%((.*)$"))
    elseif line:match("^import%s") then
      spec(line:match("^import%s+(.*)$"))
    elseif line:match("^func%s") or line:match("^type%s") or line:match("^var%s") or line:match("^const%s") then
      break
    end
  end
  return result
end

--- Resolve a package qualifier to an import path.
---@param imports { alias: string?, path: string }[]
---@param qualifier string
---@return string?
function M.resolve_qualifier(imports, qualifier)
  for _, imp in ipairs(imports) do
    if imp.alias == qualifier then
      return imp.path
    end
  end
  for _, imp in ipairs(imports) do
    if not imp.alias and M.import_names(imp.path)[1] == qualifier then
      return imp.path
    end
  end
  for _, imp in ipairs(imports) do
    if not imp.alias and vim.tbl_contains(M.import_names(imp.path), qualifier) then
      return imp.path
    end
  end
  return nil
end

return M
