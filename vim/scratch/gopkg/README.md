# gopkg.nvim

Search Go packages on pkg.go.dev and read their documentation inside Neovim,
using [`pkgsite-cli`](https://pkg.go.dev/golang.org/x/pkgsite/cmd/pkgsite-cli).

- `:GoPkg search yaml`: search packages, pick one, and read its docs
- `:GoPkg symbol Builder`: find packages that export a symbol
- `:GoPkg doc net/http.Client.Do`: open docs at a type, function, method or field
- `:GoPkg cursor`: open docs for `http.Client` under the cursor in a Go file
- In the doc buffer, `gd` follows links, `gs` picks a symbol, `gO` shows an outline, and `]]`/`[[` move between declarations

Requires Neovim 0.10+ and `pkgsite-cli` in `$PATH`. It has no plugin dependencies.
Pickers use `vim.ui.select`, so they pick up your telescope, fzf-lua or snacks UI override.

## Install

```lua
-- lazy.nvim
{
  "nk2ge5k/gopkg.nvim",
  cmd = "GoPkg",
  keys = {
    { "<leader>K", "<Plug>(gopkg-cursor)", ft = "go", desc = "Go package docs" },
    { "<leader>gp", "<Plug>(gopkg-search)", desc = "Search Go packages" },
  },
  opts = {},
}
```

Options and all mappings are described in `:help gopkg`.
