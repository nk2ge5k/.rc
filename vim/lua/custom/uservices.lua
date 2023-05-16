local Terminal = require("custom.terminal")
local notify = require("notify")
local Job = require("plenary.job")

local telescope = require("telescope")

local query_test_function = vim.treesitter.query.parse_query(
        "python",
        [[
(function_definition
  name: (identifier) @function_name
  (#match? @function_name "^test_.+")
  ) @function
]]
    )

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

local get_root = function(bufnr, lang)
  local parser = vim.treesitter.get_parser(bufnr, lang, {})
  local tree = parser:parse()[1]
  return tree:root()
end

local get_test_function = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if vim.bo[bufnr].filetype ~= "python" then
    local message = string.format(
            "cannot get test function from %s file",
            vim.bo[bufnr].filetype
        )
    notify({ message }, "warn", { title = "Test function" })

    return nil
  end

  local root = get_root(bufnr)
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

  local matches = query_test_function:iter_captures(root, bufnr, 0, row)
  while true do
    local id, node = matches()
    if not node then
      return nil
    end

    local start_row, _, end_row, _ = node:range()
    local name = query_test_function.captures[id]

    if name == "function" and start_row <= row and row <= end_row then
      local capture_id, caplture_node = matches()
      local capture_name = query_test_function.captures[capture_id]

      if capture_name == "function_name" then
        return vim.treesitter.get_node_text(caplture_node, bufnr)
      end
    end
  end

  return nil
end

local try_uservices_dirctory = function(directory)
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

  return nil
end

local extract_uservices_directory = function(directory)
  local dir = try_uservices_dirctory(directory)
  if dir ~= nil then
    return dir
  end

  notify({
      "Directory is not inside uservices directory",
      directory,
  }, "error")
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
  local remote = nil

  -- self.__index = self
  if vim.g.project_remote ~= nil then

  end

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

function Project:_reset_term()
  -- self.term:run({ command = "\\<c-c>", skip_validation = true })
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
  self:_reset_term()

  if not o then
    o = {}
  end

  if self.is_tier0 then
    local args = extend({ "tool", "tt", "test", "-Y", "'-j 6'", "-S", self.name }, o.options)

    if o.file then
      if o.function_name then
        args = extend(args, { "-F", "'*" .. o.file .. "::" .. o.function_name .. "*'" })
      else
        args = extend(args, { "-F", "'*" .. o.file .. "*'" })
      end
    end

    self.term:run({ command = "ya", args = args, cwd = self.directory })
  else
    local env = nil
    local args = extend({ "testsuite" }, o.options)
    if o.file then
      if o.function_name then
        env = { PYTEST_ARGS = "-k " .. o.function_name .. " -vv" }
      else
        env = { PYTEST_ARGS = "-k " .. o.file .. " -vv" }
      end
    end

    self.term:run({ "make", args = args, cwd = self.directory, env = env })
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
  self:_make({ "compile-db-" .. name })
end

function Project:format()
  local name = self:_command_name()
  self:_make({ "format-" .. name })
end

function Project:deploy()
  local name = self:_command_name()
  self:_make({ "deploy-testing-" .. name })
end

function Project:gen()
  local name = self:_command_name()
  self:_make({ "gen-" .. name })
end

function Project:force_gen()
  local name = self:_command_name()
  self:_make({ "arc-gen-force-" .. name })
end

function Project:_make(args)
  notify({ "Start make " .. table.concat(args, " ") }, "info")
  local stderr = {}

  Job:new({
      command = "make",
      args = args,
      cwd = self._uservices_directory,
      detached = true,
      on_stderr = function(_, data)
        table.insert(stderr, data)
      end,
      on_exit = function(_, signal)
        if signal == 0 then
          notify({ "Success make " .. table.concat(args, " ") }, "info")
        else
          table.insert(stderr, 1, "Error make " .. table.concat(args, " "))
          notify(stderr, "error")
        end
      end,
  }):start()
end

vim.api.nvim_create_user_command(
    'PTest', function(input)
  Project:open():test({ options = input.fargs })
end, { nargs = "*" })

vim.api.nvim_create_user_command(
    'PCommands', function()
  Project:open():make_compile_commands()
end, {}
)

vim.api.nvim_create_user_command(
    'PFormat', function()
  Project:open():format()
end, {}
)

vim.api.nvim_create_user_command(
    'PDeploy', function()
  Project:open():deploy()
end, {}
)

vim.api.nvim_create_user_command(
    'PGen', function()
  Project:open():gen()
end, {}
)

vim.api.nvim_create_user_command(
    'PForceGen', function()
  Project:open():force_gen()
end, {}
)

-- Run all tests
vim.keymap.set("n", "<leader>fa", function()
  Project:open():test()
end, { silent = true })

-- Run tests in current file
vim.keymap.set("n", "<leader>ff", function()
  Project:open(vim.fn.expand('%:p:h')):test({
      file = vim.fn.expand('%:t'),
  })
end, { silent = true })

-- Run test under cursor
vim.keymap.set("n", "<leader>fi", function()
  local function_name = get_test_function()
  if not function_name then
    notify("Failed to find test function", "warn", { title = "Test function" })
    return
  end

  Project:open(vim.fn.expand('%:p:h')):test({
      file = vim.fn.expand('%:t'),
      function_name = function_name,
  })
end, { silent = true })

return {
    is_uservices_directory = function(path)
      return try_uservices_dirctory(path) ~= nil
    end
}
