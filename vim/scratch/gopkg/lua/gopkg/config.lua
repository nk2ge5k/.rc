local M = {}

---@class gopkg.Config
---@field cmd string pkgsite-cli executable
---@field limit integer max search results
---@field split "vsplit"|"split"|"tab"|"current" how to open the doc window
---@field examples boolean include examples in docs
---@field keymaps boolean set buffer-local keymaps in doc buffers
---@field server string? pkgsite server URL (-server)
---@field goos string? target GOOS
---@field goarch string? target GOARCH
---@field timeout string? request timeout passed to -timeout (e.g. "30s")
M.defaults = {
  cmd = "pkgsite-cli",
  limit = 25,
  split = "vsplit",
  examples = true,
  keymaps = true,
  server = nil,
  goos = nil,
  goarch = nil,
  timeout = nil,
}

---@type gopkg.Config
M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
