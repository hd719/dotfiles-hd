local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"

opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2

opt.wrap = true
opt.linebreak = true
opt.fixendofline = true

opt.ignorecase = true
opt.smartcase = true
-- Keep the cursor line vertically centered: 999 forces the view to always
-- center as you move up and down.
opt.scrolloff = 999
opt.sidescrolloff = 8

opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.undofile = true
opt.confirm = true
opt.autoread = true

opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.updatetime = 250
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }

-- Structure-aware folding via Tree-sitter. Files open fully unfolded
-- (foldlevel 99); fold on demand with the Space z maps or the native z commands.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

vim.filetype.add({
  extension = {
    js = "javascriptreact",
    tmpl = "html",
  },
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})

-- Reload buffers when their file changes on disk (e.g. edits from the Cursor
-- agent) so Neovim never shows a stale copy. Only unmodified buffers reload; a
-- buffer with unsaved edits still triggers Neovim's warning instead of losing
-- work.
local autoreload = vim.api.nvim_create_augroup("AutoReloadFromDisk", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
  group = autoreload,
  desc = "Check whether the file changed on disk",
  callback = function()
    if vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = autoreload,
  desc = "Announce a disk-triggered reload",
  callback = function()
    vim.notify("Buffer reloaded (changed on disk)", vim.log.levels.INFO)
  end,
})
