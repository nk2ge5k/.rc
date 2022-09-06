local Terminal = require("custom.terminal")
local notify = require("notify")
local Job = require("plenary.job")


-- {{{ utils

local LIBRARY = 1
local SERVICE = 2

local _projects = {}

local is_service_directory = function(directory)
  local service_yaml = directory .. "/service.yaml"
  return vim.fn.getftype(service_yaml) == "file"
end

local is_library_directory = function(directory)
  local service_yaml = directory .. "/library.yaml"
  return vim.fn.getftype(service_yaml) == "file"
end

local is_tier0_project = function(directory)
  local service_yaml = directory .. "/ya.make.ext"
  return vim.fn.getftype(service_yaml) == "file"
end


local extract_uservices_directory = function(directory)
  if vim.w.uservices_directory ~= nil then
    return vim.w.uservices_directory
  end

  local prev = ''
  local root = directory

  while root ~= prev do
    if vim.fn.fnamemodify(root, ':t') == 'uservices' then
      vim.w.uservices_directory = root
      return root
    end

    prev = root
    root = vim.fn.fnamemodify(root, ':h')
  end

  error(debug.traceback, "Not inside uservices")
end


local extract_project = function(directory)
  local uservices_directory = extract_uservices_directory()

  local prev = ''
  local root = directory

  while root ~= prev and root ~= uservices_directory do

    if is_service_directory(root) then
      return root, SERVICE
    end

    if is_library_directory(root) then
      return root, LIBRARY
    end

    prev = root
    root = vim.fn.fnamemodify(root, ':h')
  end

  error(debug.traceback, "Not inside uservices")
end

local extend = function(tbl, other)
  if not other then
    return tbl
  end

  for _, val in ipairs(other) do
    tbl[#tbl + 1] = val
  end

  return tbl
end

-- }}}


local Project = {}
Project.__index = Project

function Project:open(directory)
  if not directory then
    directory = vim.fn.getcwd()
  end


  local uservices_directory = extract_uservices_directory(directory)
  local project_diretory, type = extract_project(directory)

  -- self.__index = self

  local obj = {
    _uservices_directory = uservices_directory,
    directory = project_diretory,
    type = type,
    is_tier0 = is_tier0_project(project_diretory),
    name = vim.fn.fnamemodify(project_diretory, ":t"),
    term = nil,
  }

  return setmetatable(obj, self)
end

-- {{{ private

---@private Helper function that allows to initilize project at any point
--          of execution
function Project:_init()
  self:_add()
  self:_term_init()
end

---@private Adds self to the list of existing projects
function Project:_add()
  if not _projects[self.directory] then
    _projects[self.directory] = self
  end
end

---@private Returns name of the projects for make command
function Project:_command_name()
  if self.type == LIBRARY then
    return "lib-" .. self.name
  end
  return self.name
end

---@private Creates new terminal for project
function Project:_term_init()
  if self.term == nil then
    self.term = Terminal:new({
      name = self:_command_name(),
      env = {
        NPROCS = 8,
        UPROJECT_DIR = self.directory,
      },
      cwd = self.directory,
    })
  end
end

-- }}}

function Project:prepare()
  self:_init()

  if self.is_tier0 then
    -- nothing to do
    return
  end

  -- 1. get or create terminal
  -- 2. run command

end

function Project:test(o)
  self:_init()

  if not o then
    o = {}
  end

  if self.is_tier0 then
    local args = extend({ "make", "-j", "8", "-A" }, o.options)

    if o.file then
      args = extend(args, { "-F", "'*" .. o.file .. "*'" })
    end

    if self.type == SERVICE then
      args[#args + 1] = "testsuite"
    end
    self.term:run({ command = "ya", args = args, cwd = self.directory })
  else
    local args = extend({ "testsuite" }, o.options)
    self.term:run({ "make", args = args, cwd = self.directory })
  end

  -- Terminal::new({
  --   name = self.name,
  --   cwd = cwd,
  --   executable = "make",
  --   command = cmd,
  -- })
end

function Project:make_compile_commands()
  local name = self:_command_name()
  local title = "Compile commands " .. name

  notify({ "Command compilation started..." }, "info", { title = title })
  local stderr = {}

  Job:new({
    command = "make",
    args = { "compile-db-" .. name },
    cwd = self._uservices_directory,
    detached = true,
    on_stderr = function(_, data)
      table.insert(stderr, data)
    end,
    on_exit = function(_, signal)
      if signal == 0 then
        notify({ "Compile command successfully created" }, "info", {
          title = title,
        })
      else
        table.insert(stderr, 1,
          string.format("Command compilation failed with code: %s", signal))
        notify(stderr, "error", { title = title })
      end
    end,
  }):start()
end

vim.api.nvim_create_user_command(
  'PTest', function(input)
    Project:open():test({ options = input.fargs })
  end, { nargs = "*" })

vim.api.nvim_create_user_command(
  'PTestFile', function(input)
    local file_name = vim.fn.expand('%:t')
    Project:open():test({
      file = file_name,
      options = input.fargs,
    })
  end, { nargs = "*" })

vim.api.nvim_create_user_command(
  'PCommands', function()
    Project:open():make_compile_commands()
  end, {}
)
