return {
  'rcarriga/nvim-notify',
  config = function()
    local notify = require("notify")
    notify.setup({
      icons = {
        DEBUG = "DEBUG",
        ERROR = "ERROR",
        INFO = "INFO",
        TRACE = "TRACE",
        WARN = "WARN"
      },
      stages = "static",
      timeout = 4000,
    })
    vim.notify = notify
  end
}
