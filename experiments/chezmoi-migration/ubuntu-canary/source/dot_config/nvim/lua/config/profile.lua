local name = vim.env.DOTFILES_NVIM_PROFILE or "full"

if name ~= "full" and name ~= "thin" then
  vim.api.nvim_err_writeln("Unknown Neovim profile: " .. name)
  vim.cmd("cquit 1")
end

return {
  name = name,
  is_full = name == "full",
  is_thin = name == "thin",
}
