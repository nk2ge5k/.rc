local actions = require('telescope.actions')

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

local configs = {
    {
        name = "uservices",
        path = home_dir .. "/src/github.yandex-team.ru/nk2ge5k/uservices"
    },
    {
        name = "backend_platform",
        path = home_dir .. "/src/bb.yandex-team.ru/eda/backend_platform"
    }
}


local custom = {}

for _, config in ipairs(configs) do
    -- TODO: may be make remaps in lua instead of vimrc
    custom[config.name .. "_files"] = function()
        if exists(config.path) then
            require("telescope.builtin").find_files({
                prompt_title = config.name .. " files",
                cwd = config.path,
            })
        else
            print('directory ' .. config.path .. ' does not exists')
        end
    end

    custom[config.name .. "_grep"] = function()
        if exists(config.path) then
            require("telescope.builtin").live_grep({
                prompt_title = config.name .. " grep",
                cwd = config.path,
            })
        else
            print('directory ' .. config.path .. ' does not exists')
        end
    end
end

return custom
