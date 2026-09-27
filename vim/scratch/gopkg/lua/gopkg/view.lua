-- Documentation buffer: rendering, navigation and keymaps.
local config = require("gopkg.config")
local parse = require("gopkg.parse")

local M = {}

---@class gopkg.BufState
---@field pkg gopkg.Package
---@field symbols gopkg.Symbol[]
---@field by_name table<string, gopkg.Symbol>

---@type table<integer, gopkg.BufState>
M.state = {}

local PREFIX = "gopkg://"

local function notify(msg, level)
  vim.notify("gopkg: " .. msg, level or vim.log.levels.INFO)
end
M.notify = notify

---@param pkg gopkg.Package
local function header(pkg)
  local version = pkg.version or ""
  if pkg.isLatest then
    version = version .. " (latest)"
  end
  local lines = {
    ("> **%s**%s"):format(pkg.path, pkg.isStandardLibrary and " (standard library)" or ""),
    ">",
    ("> Module: `%s` · Version: `%s` · Context: `%s/%s`"):format(
      pkg.modulePath or "",
      version,
      pkg.goos or "all",
      pkg.goarch or "all"
    ),
    "",
  }
  return lines
end

--- Find a visible gopkg window in the current tabpage.
local function find_doc_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if M.state[buf] then
      return win
    end
  end
end

local function open_win(buf)
  local cur = vim.api.nvim_get_current_buf()
  if M.state[cur] then
    vim.api.nvim_win_set_buf(0, buf)
    return vim.api.nvim_get_current_win()
  end
  local win = find_doc_win()
  if win then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_buf(win, buf)
    return win
  end
  local split = config.options.split
  if split == "tab" then
    vim.cmd("tab split")
  elseif split == "split" then
    vim.cmd("split")
  elseif split == "vsplit" then
    vim.cmd("vsplit")
  end
  vim.api.nvim_win_set_buf(0, buf)
  return vim.api.nvim_get_current_win()
end

--- Resolve a symbol name (or pkgsite anchor) to a line in `buf`.
---@return integer? lnum
function M.find(buf, name)
  local st = M.state[buf]
  if not st or not name then
    return nil
  end
  local sym = st.by_name[name]
  if sym then
    return sym.lnum
  end
  if name:match("^hdr%-") then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local needle = "{#" .. name .. "}"
    for i, l in ipairs(lines) do
      if l:find(needle, 1, true) then
        return i
      end
    end
  end
  -- Case-insensitive / suffix fallback, e.g. "Grow" -> "Builder.Grow".
  local lname = name:lower()
  for _, s in ipairs(st.symbols) do
    if s.name:lower() == lname then
      return s.lnum
    end
  end
  for _, s in ipairs(st.symbols) do
    if s.name:match("%." .. vim.pesc(name) .. "$") then
      return s.lnum
    end
  end
end

--- Jump to a symbol in the given doc window.
---@return boolean found
function M.jump(win, name)
  local buf = vim.api.nvim_win_get_buf(win)
  local lnum = M.find(buf, name)
  if not lnum then
    return false
  end
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! m'")
    -- Put the opening ```go fence at the top of the window, cursor on the declaration.
    vim.api.nvim_win_set_cursor(win, { math.max(lnum - 1, 1), 0 })
    vim.cmd("normal! zt")
    vim.api.nvim_win_set_cursor(win, { lnum, 0 })
  end)
  return true
end

---@param pkg gopkg.Package
---@param symbol string?
function M.show(pkg, symbol)
  local name = ("%s%s@%s"):format(PREFIX, pkg.path, pkg.version or "latest")
  local buf = vim.fn.bufnr(name)
  if buf == -1 or not M.state[buf] then
    if buf == -1 then
      buf = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_buf_set_name(buf, name)
    end
    local lines = header(pkg)
    vim.list_extend(lines, vim.split(pkg.docs or "", "\n", { plain = true }))
    while #lines > 0 and lines[#lines] == "" do
      table.remove(lines)
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].modified = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    local symbols, by_name = parse.index(lines)
    M.state[buf] = { pkg = pkg, symbols = symbols, by_name = by_name }
    vim.api.nvim_create_autocmd("BufWipeout", {
      buffer = buf,
      once = true,
      callback = function()
        M.state[buf] = nil
      end,
    })
    if config.options.keymaps then
      M.set_keymaps(buf)
    end
  end

  local win = open_win(buf)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].concealcursor = "n"
  if symbol then
    -- `DefaultClient.Do` is not a documented symbol; fall back to `DefaultClient`.
    local parent = symbol:match("^(.*)%.[^.]+$")
    if not M.jump(win, symbol) and not (parent and M.jump(win, parent)) then
      notify(("symbol %s not found in %s"):format(symbol, pkg.path), vim.log.levels.WARN)
    end
  end
end

--- Symbol under cursor inside a doc buffer, e.g. "Builder.Grow" or "Client".
local function word_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local s, e = col, col
  while s > 1 and line:sub(s - 1, s - 1):match("[%w_.]") do
    s = s - 1
  end
  while e <= #line and line:sub(e, e):match("[%w_.]") do
    e = e + 1
  end
  local word = line:sub(s, e - 1):gsub("^%.+", ""):gsub("%.+$", "")
  return word ~= "" and word or nil
end

--- Follow the link (or symbol reference) under cursor.
function M.follow()
  local buf = vim.api.nvim_get_current_buf()
  local st = M.state[buf]
  if not st then
    return
  end
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local link = parse.link_at(line, col)
  if link then
    local t = parse.classify_link(link.target)
    if t.kind == "url" then
      vim.ui.open(t.url)
    elseif t.kind == "anchor" then
      if not M.jump(0, t.anchor) then
        notify("anchor not found: " .. t.anchor, vim.log.levels.WARN)
      end
    else
      require("gopkg").open(t.pkg, t.anchor)
    end
    return
  end

  local word = word_under_cursor()
  if not word then
    return
  end
  if M.jump(0, word) then
    return
  end
  -- `pkg.Symbol` referencing another package: resolve using the package's
  -- own import names is not available, so try the qualifier as a std path.
  local qual, rest = word:match("^([%l][%w_]*)%.(%u.*)$")
  if qual then
    require("gopkg").open(qual, rest)
    return
  end
  notify("nothing to follow under cursor", vim.log.levels.WARN)
end

--- Select a symbol from the doc buffer and jump to it.
function M.pick_symbol(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local st = M.state[buf]
  if not st then
    return notify("not a gopkg buffer", vim.log.levels.WARN)
  end
  vim.ui.select(st.symbols, {
    prompt = st.pkg.path .. " symbols",
    format_item = function(s)
      return ("%-6s %s  %s"):format(s.kind, s.name, s.text)
    end,
  }, function(choice)
    if not choice then
      return
    end
    local win = vim.fn.bufwinid(buf)
    if win == -1 then
      win = open_win(buf)
    end
    vim.api.nvim_set_current_win(win)
    M.jump(win, choice.name)
  end)
end

--- Populate the location list with the package outline.
function M.outline(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local st = M.state[buf]
  if not st then
    return
  end
  local items = {}
  for _, s in ipairs(st.symbols) do
    if s.top then
      table.insert(items, { bufnr = buf, lnum = s.lnum, col = 1, text = ("%-6s %s"):format(s.kind, s.name) })
    end
  end
  vim.fn.setloclist(0, {}, " ", { title = st.pkg.path, items = items })
  vim.cmd("lopen")
end

--- Jump to next/previous top-level declaration.
function M.step(dir)
  local st = M.state[vim.api.nvim_get_current_buf()]
  if not st then
    return
  end
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lnums = {}
  for _, s in ipairs(st.symbols) do
    if s.top and (dir > 0 and s.lnum > cur or dir < 0 and s.lnum < cur) then
      table.insert(lnums, s.lnum)
    end
  end
  local target
  if dir > 0 then
    target = lnums[math.min(vim.v.count1, #lnums)]
  else
    target = lnums[math.max(#lnums - vim.v.count1 + 1, 1)]
  end
  if target then
    vim.cmd("normal! m'")
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end
end

--- pkg.go.dev URL for the buffer, anchored at the nearest symbol above cursor.
function M.url(buf)
  local st = M.state[buf]
  if not st then
    return
  end
  local url = ("https://pkg.go.dev/%s@%s"):format(st.pkg.path, st.pkg.version)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local best
  for _, s in ipairs(st.symbols) do
    if s.lnum <= cur then
      best = s
    else
      break
    end
  end
  if best then
    url = url .. "#" .. best.name
  end
  return url
end

function M.set_keymaps(buf)
  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = "gopkg: " .. desc })
  end
  map("gd", M.follow, "follow link / symbol")
  map("<CR>", M.follow, "follow link / symbol")
  map("<C-]>", M.follow, "follow link / symbol")
  map("gs", function()
    M.pick_symbol(buf)
  end, "pick symbol")
  map("gO", function()
    M.outline(buf)
  end, "outline")
  map("]]", function()
    M.step(1)
  end, "next declaration")
  map("[[", function()
    M.step(-1)
  end, "previous declaration")
  map("gx", function()
    local line = vim.api.nvim_get_current_line()
    local link = parse.link_at(line, vim.api.nvim_win_get_cursor(0)[2] + 1)
    if link then
      local t = parse.classify_link(link.target)
      if t.kind == "url" then
        return vim.ui.open(t.url)
      elseif t.kind == "package" then
        return vim.ui.open("https://pkg.go.dev/" .. t.pkg .. (t.anchor and ("#" .. t.anchor) or ""))
      end
    end
    vim.ui.open(M.url(buf))
  end, "open on pkg.go.dev")
  map("q", function()
    if not pcall(vim.cmd.close) then
      vim.cmd.bprevious()
    end
  end, "close")
end

return M
