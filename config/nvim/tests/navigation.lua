-- Run after restoring the locked Snacks and Oil plugins:
-- nvim --headless -u NONE -l config/nvim/tests/navigation.lua
local config = vim.fn.getcwd() .. "/config/nvim"
package.path = config .. "/lua/?.lua;" .. package.path
for _, plugin in ipairs({ "snacks.nvim", "oil.nvim" }) do
  vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/" .. plugin)
end
local snacks = require("snacks")
require("oil").setup({ default_file_explorer = false })
local specs = dofile(config .. "/lua/plugins/navigation.lua")
local open
for _, key in ipairs(specs[1].keys) do
  if key[1] == "<leader>e" then
    open = key[2]
  end
end
assert(open, "Space e mapping missing")

-- Keep filesystem/root resolution real; capture only the picker UI boundary.
local opened, opened_ignored, existing, closed, revealed, focused
snacks.explorer = setmetatable({
  reveal = function(opts)
    revealed = opts.file
  end,
}, {
  __call = function(_, opts)
    opened = opts.cwd
    opened_ignored = opts.ignored
  end,
})
snacks.picker.get = function()
  return existing and { existing } or {}
end
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
dir = assert(vim.uv.fs_realpath(dir))
local repo = dir .. "/other repo"
local loose = dir .. "/loose"
vim.fn.mkdir(repo .. "/src", "p")
vim.fn.mkdir(loose, "p")
vim.fn.system({ "git", "init", "-q", repo })
assert(vim.v.shell_error == 0, "fixture git init failed")
vim.cmd.cd(dir)

local function check(path, expected, filetype, buftype)
  vim.cmd.enew()
  if path then
    vim.api.nvim_buf_set_name(0, path)
  end
  vim.bo.filetype = filetype or ""
  vim.bo.buftype = buftype or ""
  opened = nil
  open()
  assert(
    opened == expected,
    "wrong explorer root: " .. tostring(opened) .. ", expected " .. expected
  )
  vim.api.nvim_buf_delete(0, { force = true })
end

check(repo .. "/src/new.lua", repo)
check(loose .. "/notes.md", loose)
check(nil, dir)
check("oil://" .. loose .. "/", loose, "oil", "acwrite")
check("term://" .. repo .. "//123:zsh", dir, "", "nofile")
check("health://plugins", dir, "checkhealth", "nofile")

-- A gitignored file (e.g. generated code) must stay revealable in the tree.
vim.fn.mkdir(repo .. "/src/generated", "p")
vim.fn.writefile({ "src/generated" }, repo .. "/.gitignore")
check(repo .. "/src/generated/api.ts", repo)
assert(opened_ignored == true, "ignored file opened without showing ignored files")
check(repo .. "/src/new.lua", repo)
assert(opened_ignored == nil, "tracked file should keep the default ignored setting")

existing = {
  cwd = function()
    return repo
  end,
  opts = {},
  is_focused = function()
    return focused
  end,
  focus = function()
    focused = true
  end,
  close = function()
    closed = true
  end,
}
check(loose .. "/notes.md", loose)
assert(closed, "switching repositories did not close the old explorer")

closed, opened, opened_ignored, revealed, focused = false, nil, nil, nil, false
vim.cmd.edit(vim.fn.fnameescape(repo .. "/src/generated/api.ts"))
open()
assert(closed, "ignored file did not replace the tracked-file explorer")
assert(opened == repo and opened_ignored == true, "ignored file did not reopen with ignored files")

existing.opts.ignored = true
closed, opened, revealed, focused = false, nil, nil, false
vim.cmd.edit(vim.fn.fnameescape(repo .. "/src/generated/api.ts"))
open()
assert(not closed, "Space e closed the explorer instead of revealing the file")
assert(opened == nil, "Space e reopened the explorer when it only needed to reveal")
assert(revealed == repo .. "/src/generated/api.ts", "Space e did not reveal the current file")
assert(focused, "Space e did not focus the explorer")

closed, opened, revealed = false, nil, nil
focused = true
vim.cmd.edit(vim.fn.fnameescape(repo .. "/src/new.lua"))
open()
assert(closed and opened == nil, "Space e did not toggle the focused explorer closed")
vim.fn.delete(dir, "rf")
print("Explorer navigation tests passed")
