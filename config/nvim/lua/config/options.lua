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
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.undofile = true
opt.confirm = true

opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.updatetime = 250
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }

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
