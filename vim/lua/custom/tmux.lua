local Job = require "plenary.job"

local config = {
  -- tmux executable
  executable = "tmux"
}

local concat_into = function(dst, rhs)
  for i = 1, #rhs do
    dst[#dst + 1] = rhs[i]
  end
  return dst
end

local Popup = {}
Popup.__index = Popup

function Popup:new(o)
  if not o then
    error(debug.traceback "Options are required for Popup:new")
  end

  local obj = {}
  obj._width = o.widith
  obj._height = o.height

  return setmetatable(obj, self)
end

function Popup:run(o)
  if not o then
    error(debug.traceback "Options are required for Popup:command")
  end

  if o.command == nil then
    error(debug.traceback "No command to run in popup window")
  end

  if o.cwd == nil then
    o.cwd = vim.fn.getcwd()
  end

  local cmd = concat_into({
    "popup",
    '-w', self._width .. "%",
    "-h", self._height .. "%",
    "-d", o.cwd,
    "-E"
  }, o.command)

  Job:new({
    config.executable,
    args = cmd,
    cwd = o.cwd,
    interactive = false,
    detached = true,
  }):start()
end

local popup = Popup:new({
  widith = 60,
  height = 80,
})

-- Popup with vimwiki diary for today
vim.keymap.set("n", "<leader>o", function()
  popup:run({
    command = { "nvim", "-c", "VimwikiMakeDiaryNote" },
  })
end)
