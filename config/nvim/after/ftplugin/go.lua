if require("config.profile").is_thin then
  return
end

vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 0
