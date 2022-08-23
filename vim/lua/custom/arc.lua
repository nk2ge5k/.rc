local Job = require "plenary.job"

local trim = function(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local arc_cmd = function(cmd, cwd)
  local stderr = {}

  if not cwd then
    cwd = vim.fn.getcwd()
  end

  local stdout, ret = Job
      :new({
        command = "arc",
        args = cmd,
        cwd = cwd,
        on_stderr = function(_, data)
          table.insert(stderr, data)
        end,
      })
      :sync()

  if ret ~= 0 then
    error(debug.traceback, string.format(
      "Arc command %s failed: %s",
      table.concat(cmd, " "),
      table.concat(stderr, " ")
    ))
  end

  return stdout
end

-- Returns path to arcadia root
local arc_root = function(cwd)
  if vim.g.arc_root == nil then
    vim.g.arc_root = trim(table.concat(arc_cmd({"root"}, cwd), " "))
  end
  return vim.g.arc_root
end

local is_arc_directory = function(dir)
  return pcall(arc_root, dir)
end

-- Returns table of changes in current worktree
-- {
--   "status": {
--     "changed": [
--       {
--         "status": "modified",
--         "path": "path/to/file"
--       }
--     ]
--   }
-- }
local arc_status = function()
  return assert(vim.json.decode(arc_cmd({"status", "--json"})))
end

local arc = {
  root = arc_root,
  owns = is_arc_directory,
  status = arc_status,
}

local creat_arc_window = function()
  vim.api.nvim_command('botright vnew') -- We open a new vertical window at the far right
  local arc_buffer = vim.api.nvim_get_current_buf() -- ...and it's buffer handle.

  vim.api.nvim_buf_set_name(arc_buffer, 'Arcadia Status')

  -- Now we set some options for our buffer.
  -- nofile prevent mark buffer as modified so we never get warnings about not saved changes.
  -- Also some plugins treat nofile buffers different.
  -- For example coc.nvim don't triggers aoutcompletation for these.
  vim.api.nvim_buf_set_option(arc_buffer, 'buftype', 'nofile')
  -- We do not need swapfile for this buffer.
  vim.api.nvim_buf_set_option(arc_buffer, 'swapfile', false)
  -- And we would rather prefer that this buffer will be destroyed when hide.
  vim.api.nvim_buf_set_option(arc_buffer, 'bufhidden', 'wipe')
  -- It's not necessary but it is good practice to set custom filetype.
  -- This allows users to create their own autocommand or colorschemes on filetype.
  -- and prevent collisions with other plugins.
  vim.api.nvim_buf_set_option(arc_buffer, 'filetype', 'arc')

  vim.keymap.set('n', '<leader>h', function()
    print("Hello keymap")
  end, { buffer = arc_buffer })

  return arc_buffer
end

local show_status = function(buffer)
  local root = arc.root()
  local output = arc.status()

  local lines = {
    arc.root(),
    vim.fn.getcwd(),
    "",
  }

  local modes = {
    deleted = "D",
    modified = "M",
  }

  local changed = output["status"]["changed"]

  for _, file in ipairs(changed) do
    local path = root .. "/" .. file.path
    local mode = modes[file.status] or "?"
    table.insert(lines, #lines + 1, string.format("%s %s", mode, path))
  end

  -- We apply results to buffer
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  -- And turn off editing
  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
end

return arc
