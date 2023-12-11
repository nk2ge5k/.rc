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

local copyright = function()
  return {
    string.format("/* %s", vim.fn.expand("%:t")),
    " *",
    string.format(" * Copyright (c) %s, George Chernukhin <nk2ge5k at gmail dot com>", os.date("%Y")),
    " * All rights reserved.",
    " *",
    " * Redistribution and use in source and binary forms, with or without",
    " * modification, are permitted provided that the following conditions are met:",
    " *",
    " *   * Redistributions of source code must retain the above copyright notice,",
    " *     this list of conditions and the following disclaimer.",
    " *   * Redistributions in binary form must reproduce the above copyright",
    " *     notice, this list of conditions and the following disclaimer in the",
    " *     documentation and/or other materials provided with the distribution.",
    " *   * Neither the project name of nor the names of its contributors may be used",
    " *     to endorse or promote products derived from this software without",
    " *     specific prior written permission.",
    " *",
    " * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"",
    " * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE",
    " * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE",
    " * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE",
    " * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR",
    " * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF",
    " * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS",
    " * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN",
    " * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)",
    " * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE",
    " * POSSIBILITY OF SUCH DAMAGE.",
    " */",
  }
end

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
vim.keymap.set({ "i", "s" }, "<c-u>", function()
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
  local user = vim.fn.getenv("USER")

  ls.add_snippets("all", {
    -- todo comment
    ls.snippet("todo", {
      choice(1, {
        t("TODO(" .. user .. "): "),
        t("NOTE(" .. user .. "): "),
        t("FIXME(" .. user .. "): "),
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
    ls.snippet("copyright", t(copyright())),
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
      func(function(index)
        local parts = vim.split(index[1][1], ".", true)
        return parts[#parts] or ""
      end, { 1 }),
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
