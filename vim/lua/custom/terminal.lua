-- {{{ utils

local _terminals = {}
local _by_name = {}

local _insert = function(dst, ...)
  local args = { n = select("#", ...), ... }
  for _, val in ipairs(args) do
    table.insert(dst, val)
  end
end

local _next_term_id = function()
  for index, term in pairs(_terminals) do
    if index ~= term.id then return index end
  end
  return #_terminals + 1
end


local _get_dir = function(dir)
  if not dir then
    return vim.fn.getcwd()
  end
  return dir
end

local _handle_exit = function(term)
  if term.on_exit then
    return function(...)
      term:on_exit(...)
    end
  end

  if term.close_on_exit then
    return function(...)
      term:close()
      if vim.api.nvim_buf_is_loaded(term._bufnr) then
        vim.api.nvim_buf_delete(term._bufnr, { force = true })
      end
    end
  end
end

local _make_env = function(env)
  if not env then
    return nil
  end

  if type(env) ~= "table" then
    error "env has to be a table"
  end

  local result = {}

  for k, v in pairs(env) do
    if type(k) == "number" then
      table.insert(result, v)
    elseif type(k) == "string" then
      table.insert(result, string.format("%s=%q", k, tostring(v)))
    end
  end

  return result
end

local _find_term = function(opts)
  if opts.id then
    return _terminals[opts.id]
  end

  if opts.name then
    local id = _by_name[opts.name]
    if id then
      return _terminals[id]
    end
  end

  return nil
end

-- }}}


local Terminal = {
  -- _name        - (string|nil) terminal name
  -- _channel_id  - (int) terminal cahnnel
  -- _buffer_id   - (int) terminal buffer
  -- _is_vertical - (bool) is split should be vertical
  -- _cwd         - (string) terminal working directory
}

Terminal.__index = Terminal

local _new_terminal = function(opts)
  if not opts then
    opts = {
      vertical = true,
      name = "<unnamed>",
    }
  end

  local last_win = vim.api.nvim_get_current_win()

  if opts.vertical then
    vim.cmd('vsplit')
  else
    vim.cmd('split')
  end

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, buf)

  local job_id = vim.fn.termopen(vim.o.shell .. " # " .. opts.name, {
    cwd = _get_dir(opts.cwd),
    on_exit = opts.on_exit,
    -- on_stdout = self:__make_output_handler(self.on_stdout),
    -- on_stderr = self:__make_output_handler(self.on_stderr),
    env = opts.env,
    clear_env = opts.clear_env,
  })

  vim.fn.win_gotoid(last_win)

  return win, buf, job_id
end

local new_window = function(vertical)
  if vertical then
    vim.cmd('vnew')
  else
    vim.cmd('new')
  end

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(true, false)

  return win, buf
end

local term_key = function(name)
  return string.format("term#%s", name)
end

function Terminal:new(opts)
  opts = opts or {}

  -- Return existing terminal if we found such by id
  local term = _find_term(opts)
  if term then
    return term
  end

  local id = _next_term_id()

  self.__index = self

  local obj = {
    id = id,
    name = opts.name or ("term-" .. id),
    env = opts.env,
    clear_env = opts.clear_env or false,
    _bufnr = -1,
  }

  return setmetatable(obj, self)
end

-- {{{ private

function Terminal:_add()
  _terminals[self.id] = self
  _by_name[self.name] = self.id
end

function Terminal:_start()
  self:_add()

  if vim.api.nvim_buf_is_valid(self._bufnr) then
    return
  end

  local win, buf, chan = _new_terminal({
    name = self.name,
    cwd = _get_dir(self.dir),
    on_exit = _handle_exit(self),
    -- on_stdout = self:__make_output_handler(self.on_stdout),
    -- on_stderr = self:__make_output_handler(self.on_stderr),
    env = self.env,
    clear_env = self.clear_env,
  })

  self._channel_id = chan
  self._bufnr = buf
  self._winnr = win
end

--- }}}

function Terminal:run(o)
  self:_start()

  if not o then
    error(debug.traceback "Options are required for Terminal:run")
  end

  local command = o.command
  if not command then
    if o[1] then
      command = o[1]
    else
      error(debug.traceback "'command' is required for Terminal:new")
    end
  elseif o[1] then
    error(debug.traceback "Cannot pass both 'command' and array args")
  end

  local args = o.args
  if not args then
    if #o > 1 then
      args = { select(2, unpack(o)) }
    else
      args = {}
    end
  end

  local ok, is_exe = pcall(vim.fn.executable, command)
  if not o.skip_validation and ok and 1 ~= is_exe then
    error(debug.traceback(command .. ": Executable not found"))
  end

  local cmd = {}

  if o.cwd ~= nil and o.cwd ~= self.cwd then
    _insert(cmd, "cd", o.cwd, "&&")
    self.cwd = o.cwd
  end

  if o.env then
    _insert(cmd, unpack(_make_env(o.env)))
  end

  _insert(cmd, command)
  _insert(cmd, unpack(args))

  vim.fn.chansend(self._channel_id, { table.concat(cmd, " "), "" })
end

return Terminal
