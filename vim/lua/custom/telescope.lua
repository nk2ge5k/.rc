local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local finders = require('telescope.finders')

local conf = require('telescope.config').values

require('telescope').setup{
    defaults = {
        file_sorter = require('telescope.sorters').get_fzy_sorter,
        prompt_prefix = ' >',
        color_devicons = true,

        mappings = {
            i = {
                ["<C-x>"] = false,
                ["<C-q>"] = actions.send_to_qflist,
            },
        }
    },
    extensions = {
        fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
        }
    }
}

require('telescope').load_extension('fzy_native')

local home_dir = os.getenv("HOME")

function exists(name)
    if type(name)~="string" then return false end
    return os.rename(name,name) and true or false
end

local uservices_dir = home_dir .. "/src/github.yandex-team.ru/nk2ge5k/uservices"

local configs = {
    {
        name = "uservices",
        path = uservices_dir
    },
    {
        name = "eats-catalog",
        path = uservices_dir .. "/services/eats-catalog"
    },
    {
        name = "eats-layout-constructor",
        path = uservices_dir .. "/services/eats-layout-constructor"
    },
    {
        name = "eats-communications",
        path = uservices_dir .. "/services/eats-communications"
    },
    {
        name = "eats-collections",
        path = uservices_dir .. "/services/eats-collections"
    },
    {
        name = "scripts",
        path = home_dir .. "/scripts"
    },
    {
        name = "scratch",
        path = home_dir .. "/scratch"
    },
    {
        name = "github",
        path = home_dir .. "/src/github.com/nk2ge5k"
    },
    {
        name = "backend_platform",
        path = home_dir .. "/src/bb.yandex-team.ru/eda/backend_platform"
    }
}

local custom = {}

custom.projects = function(opts)
    local projects = {}

    for _, config in ipairs(configs) do
        if exists(config.path) then
            table.insert(projects, {
                name = config.name,
                path = config.path,
            })
        end
    end

    if vim.tbl_isempty(projects) then
        return
    end

    pickers.new(opts, {
        prompt_title = 'Projects',
        finder = finders.new_table {
            results = projects,
            entry_maker = function(config)
                return {
                    ordinal = config.name,
                    display = config.name,
                    filename = config.path,
                }
            end
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            local grep = function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local path = selection.filename

                require("telescope.builtin").live_grep({
                    prompt_title = path .. " grep",
                    cwd = path,
                })
            end

            map('i', '<c-g>', grep)
            map('n', 'g', grep)


            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local path = selection.filename

                require("telescope.builtin").find_files({
                    prompt_title = path .. " files",
                    cwd = path,
                })
            end)
            return true
        end
    }):find()
end

return custom
