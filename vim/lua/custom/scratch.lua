local Job = require "plenary.job"
local action_state = require "telescope.actions.state"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local from_entry = require "telescope.from_entry"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"
local putils = require "telescope.previewers.utils"
local actions = require "telescope.actions"

local arc_root = "/home/nk2ge5k/src/a.yandex-team.ru/"

local get_os_command_output = function(cmd, cwd)
  if type(cmd) ~= "table" then
    error("invalid command format")
    return {}
  end

  local command = table.remove(cmd, 1)
  local stderr = {}
  local stdout, ret = Job
    :new({
      command = command,
      args = cmd,
      cwd = cwd,
      on_stderr = function(_, data)
        table.insert(stderr, data)
      end,
    })
    :sync()
  return stdout, ret, stderr
end

local arc_file_diff = function(opts)
  return previewers.new_buffer_previewer {
    title = "Arc File Diff Preview",
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,

    define_preview = function(self, entry, status)
      if entry.status and (entry.status == "??" or entry.status == "A ") then
        local p = from_entry.path(entry, true)
        if p == nil or p == "" then
          return
        end
        conf.buffer_previewer_maker(p, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
        })
      else
        putils.job_maker({ "arc", "diff", "--git", entry.value }, self.state.bufnr, {
          value = entry.value,
          bufname = self.state.bufname,
          cwd = opts.cwd,
        })
        putils.regex_highlighter(self.state.bufnr, "diff")
      end
    end,
  }
end


--- Stage/unstage selected file
---@param prompt_bufnr number: The prompt bufnr
local arc_staging_toggle = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    return
  end

  if selection.status:sub(2) == " " then
    vim.notify("Reseting file " .. selection.value, "info")
    local _, ret, stderr = get_os_command_output({"arc", "reset", "--", selection.value}, arc_root)
    if ret ~= 0 then
      vim.notify(
        string.format("Failed to reset file %s: %s", selection.value, table.concat(stderr)),
        "error"
      )
    end
  else
    vim.notify("Adding file " .. selection.value, "info")
    local _, ret, stderr = get_os_command_output({"arc", "add", selection.value}, arc_root)
    if ret ~= 0 then
      vim.notify(
        string.format("Failed to reset file %s: %s", selection.value, table.concat(stderr)),
        "error"
      )
    end
  end
end


local arc_status = function (opts)

  opts = opts or {
    cwd = arc_root,
  }

  local gen_new_finder = function()
    local arc_cmd = { "arc", "status", "-s" }


    local output = get_os_command_output(arc_cmd, arc_root)

    if #output == 0 then
      print "No changes found"
      return
    end

    return finders.new_table {
      results = output,
      entry_maker = vim.F.if_nil(
        opts.entry_maker, make_entry.gen_from_git_status(opts)),
    }
  end

  local initial_finder = gen_new_finder()
  if not initial_finder then
    return
  end

  local toggle = function(bufnr)
    arc_staging_toggle(bufnr)

    action_state.get_current_picker(bufnr):refresh(
      gen_new_finder(), { reset_prompt = true })

    actions.move_selection_next(bufnr)
  end

  pickers.new(opts, {
    prompt_title = "Arc Status",
    finder = initial_finder,
    previewer = arc_file_diff(opts),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(_, map)
      map("i", "<tab>", toggle)
      map("n", "<tab>", toggle)

      return true
    end,
  }):find()

end

-- <c-k> expand current snippet or jump to the next item in the snippet
vim.keymap.set({"n"}, "<leader>a", function()
  arc_status()
end)
