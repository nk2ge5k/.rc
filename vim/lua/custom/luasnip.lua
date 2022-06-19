local ls = require "luasnip"
local types = require "luasnip.util.types"

local n = ls.snippet_node
local t = ls.text_node
local d = ls.dynamic_node
local r = ls.restore_node

local choice = ls.choice_node
local func = ls.function_node
local insert = ls.insert_node

local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

-- Clear snippets because i tierd of reloading
require("luasnip.session.snippet_collection").clear_snippets()

-- {{{ config

ls.config.set_config({
    -- Remember last snippet to be able to jump back into it
    history = true,
    -- Update snippet while typing
    updateevents = "TextChanged,TextChangedI",
    -- Pretty clear
    enable_autosnippets = true,

    ext_opts = {
        [types.choiceNode] = {
            active = {
                virt_text = { { " <-", "NonTest" } },
            },
        },
    },
})

-- }}}

-- {{{ keymaps

-- <c-k> expand current snippet or jump to the next item in the snippet
vim.keymap.set({"i", "s"}, "<c-k>", function()
    if ls.expand_or_jumpable() then
        ls.expand_or_jump()
    end
end, { silent = true })

-- <c-j> jump on to the previous item in the snippet
vim.keymap.set({ "i", "s" }, "<c-j>", function()
    if ls.jumpable(-1) then
        ls.jump(-1)
    end
end, { silent = false })

-- <c-l> cycle through the options
vim.keymap.set("i", "<c-l>", function()
    if ls.choice_active() then
        ls.change_choice(1)
    end
end)

-- }}}

-- {{{ all
do
    ls.add_snippets("all", {
        -- todo comment
        ls.snippet("todo", {
            choice(1, {
                t("TODO(nk2ge5k): "),
                t("NOTE(nk2ge5k): "),
                t("FIXME(nk2ge5k): "),
            }),
        }),
        -- current time
        ls.snippet("today", func(function()
            return os.date("%Y-%m-%d")
        end)),
        -- now
        ls.snippet("now", func(function()
            return os.date("%Y-%m-%dT%H:%M:%S")
        end)),
        -- current path
        ls.snippet("apath", func(function()
          return vim.fn.expand("%:p:h")
        end)),
        -- current file
        ls.snippet("afile", func(function()
          return vim.fn.expand("%:p")
        end)),
        -- current path
        ls.snippet("path", func(function()
          return vim.fn.expand("%:h")
        end)),
        -- current file
        ls.snippet("file", func(function()
          return vim.fn.expand("%")
        end)),
    })
end
-- }}}

-- {{{ cpp
do
    ls.add_snippets("cpp", {
        -- struct
        ls.snippet("stru", fmt(
            [[
            struct {} {{
                {}
            }}
            ]],
            {
                insert(1),
                insert(0),
            }
        )),
        -- header file
        ls.snippet("header", fmt(
            [[
            #pragma once

            {}

            namespace {} {{
                {}
            }}
            ]],
            {
                insert(1),
                insert(2),
                insert(0),
            }
        )),
        -- range based for
        ls.snippet("for", fmt(
            [[
            for (const auto& {}: {}) {{
                {}
            }}
            ]],
            {
                insert(1, "item"),
                insert(2, "items"),
                insert(0),
            }
        )),
        -- for loop
        ls.snippet("fori", fmt(
            [[
            for (size_t i = 0; i < {}; ++i) {{
                {}
            }}
            ]],
            {
                insert(1),
                insert(0),
            }
        )),
    })
end
-- }}}

-- {{{ lua
do
    ls.add_snippets("lua", {
        ls.snippet("req", fmt([[local {} = require("{}")]], {
            func(function (index)
                local parts = vim.split(index[1][1], ".", true)
                return parts[#parts] or ""
            end, {1}),
            insert(1),
        })),
        ls.snippet("fn", fmt(
            [[
            local {} = function ({})
                {}
            end
            ]],
            {
                insert(1),
                insert(2),
                insert(3),
            }
        )),
    })
end
-- }}}

-- {{{ rust
do
    ls.add_snippets("rust", {
        -- function
        ls.snippet("fn", fmt(
            [[
            fn {} {{
                {}
            }}
            ]],
            {
                insert(1),
                insert(0),
            }
        )),
        -- print something
        ls.snippet("pr", fmt("println!(\"{}\"{});", {
            insert(1, "{:?}"),
            insert(2),
        })),
        -- create test
        ls.snippet("modtest", fmt(
            [[
            #[cfg(test)]
            mod test {{
            {}
                {}
            }}
            ]],
            {
                choice(1, {
                    t("   use super::*;"),
                    t(""),
                }),
                insert(0),
            }
        )),
    })
end
-- }}}

-- {{{ go
do
    ls.add_snippets("go", {
        -- range
        ls.snippet("range", fmt(
            [[
            for {}, {} := range {} {{
                {}
            }}
            ]],
            {
                insert(1, "_"),
                insert(2, "item"),
                insert(3, "items"),
                insert(0),
            }
        ))
    })
end
-- }}}

-- {{{ markdown
do
    local md_header = ls.snippet("hi", {
        choice(1, {
            t("# "),
            t("## "),
            t("### "),
            t("#### "),
        }),
        insert(0),
    })

    ls.add_snippets("vimwiki", { md_header })
    ls.add_snippets("markdown", { md_header })
end
-- }}}
