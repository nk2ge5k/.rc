local CREATE_FILE_GROUP = "CFileCreateGroup"

vim.api.nvim_create_augroup(CREATE_FILE_GROUP, { clear = true })

local function to_defintion(filename)
  local no_symobls = string.gsub(filename, "[^a-zA-Z0-9]", "_")
  local no_repeats = string.gsub(no_symobls, "_+", "_")
  return string.upper(no_repeats)
end

vim.api.nvim_create_autocmd("BufNewFile", {
  group = CREATE_FILE_GROUP,
  pattern = "*.h",
  callback = function(args)
    if args.file:match("%.h$") then
      local filename = vim.api.nvim_call_function('fnamemodify', {args.file, ':t'})
      local define   = to_defintion(filename)

      vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, {
        "#ifndef " .. define,
        "#define " .. define,
        "",
        "#endif // " .. define
      })
    end
  end
})
