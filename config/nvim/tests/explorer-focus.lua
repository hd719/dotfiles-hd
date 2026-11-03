-- Run against the installed, locked Snacks plugin:
-- nvim --headless -u NONE -i NONE -l config/nvim/tests/explorer-focus.lua
local config = vim.fn.getcwd() .. "/config/nvim"
package.path = config .. "/lua/?.lua;" .. package.path
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/snacks.nvim")
local specs = dofile(config .. "/lua/plugins/navigation.lua")
local snacks = require("snacks")
snacks.setup({ picker = specs[1].opts.picker, explorer = specs[1].opts.explorer })
dofile(config .. "/lua/config/keymaps.lua")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
dir = assert(vim.uv.fs_realpath(dir))
local file = dir .. "/note.txt"
vim.fn.writefile({ "keep this file open" }, file)
vim.cmd.edit(file)
local main = vim.api.nvim_get_current_win()
local picker = snacks.explorer({ cwd = dir })
assert(
  vim.wait(2000, function()
    return picker.list.win:valid() and picker:is_focused() and picker.list:count() > 0
  end),
  "explorer did not open"
)

for _, case in ipairs({
  { window = "list", insert = false },
  { window = "input", insert = false },
  { window = "input", insert = true },
}) do
  picker:focus(case.window)
  local label = case.window .. (case.insert and " insert" or " normal")
  local keys = (case.insert and "i" or "") .. "<C-l>"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
  assert(
    vim.wait(1000, function()
      return vim.api.nvim_get_current_win() == main
    end),
    "Ctrl+L did not return to the file from " .. label
  )
  assert(not picker.closed and picker.list.win:valid(), "Ctrl+L closed Explorer from " .. label)
  assert(vim.api.nvim_buf_get_name(0) == file, "Ctrl+L changed the editor buffer")
end

-- The existing left shortcut must still return to the visible sidebar.
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-h>", true, false, true), "xt", false)
assert(picker:is_focused(), "Ctrl+H did not return to the open Explorer")
picker:close()
vim.fn.delete(dir, "rf")
print("Explorer focus tests passed")
