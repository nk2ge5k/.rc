-- Resolve `pkg.Symbol` / import paths under cursor in Go buffers.
local parse = require("gopkg.parse")

local M = {}

--- Span of characters matching `class` around 1-based column `col`.
local function span(line, col, class)
  if not line:sub(col, col):match(class) then
    return nil
  end
  local s, e = col, col
  while s > 1 and line:sub(s - 1, s - 1):match(class) do
    s = s - 1
  end
  while e < #line and line:sub(e + 1, e + 1):match(class) do
    e = e + 1
  end
  return s, e
end

--- Return the string literal containing column `col`, if any.
local function string_at(line, col)
  local init = 1
  while true do
    local s, e, str = line:find('"([^"]*)"', init)
    if not s then
      return nil
    end
    if col >= s and col <= e then
      return str
    end
    init = e + 1
  end
end

---@return string? pkg import path
---@return string? symbol, or an error message when pkg is nil
function M.resolve()
  local buf = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local imports = parse.imports(vim.api.nvim_buf_get_lines(buf, 0, -1, false))

  local str = string_at(line, col)
  if str then
    for _, imp in ipairs(imports) do
      if imp.path == str then
        return str, nil
      end
    end
  end

  local s, e = span(line, col, "[%w_.]")
  if not s then
    return nil, "no identifier under cursor"
  end
  local expr = line:sub(s, e)
  -- Parts up to (and including) the one under the cursor.
  local parts, pos = {}, s
  for part in expr:gmatch("[^.]+") do
    table.insert(parts, part)
    local ps = line:find(part, pos, true)
    pos = ps + #part
    if pos > col then
      break
    end
  end
  if #parts == 0 then
    return nil, "no identifier under cursor"
  end

  local path = parse.resolve_qualifier(imports, parts[1])
  if not path then
    return nil, ("%q is not an imported package"):format(parts[1])
  end
  if #parts == 1 then
    return path, nil
  end
  -- At most Type.Member.
  return path, table.concat(parts, ".", 2, math.min(#parts, 3))
end

return M
