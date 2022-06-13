local curl = require "plenary.curl"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"


local test_picker = function(opts)
  local response = curl.request {
    url = "https://postman-echo.com/post",
    method = "post",
    accept = "application/json",
    headers = {
      content_type = "application/json",
    },
    body = vim.fn.json_encode({hello="friend", some={1, 2, 120}}),
  }
  local json = vim.fn.json_decode(response.body).json
  vim.inspect(json)
  -- By creating the entry maker after the cwd options,
  -- we ensure the maker uses the cwd options when being created.
  opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_file(opts))
  pickers.new(opts, {
    prompt_title = "Test",
    finder = finders.new_table({"hello", "world"}),
  }):find()
end

test_picker({})
