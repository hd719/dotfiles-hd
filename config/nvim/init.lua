vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.dotfiles_nvim_profile = require("config.profile").name

require("config.options")
require("config.keymaps")
require("config.lazy")
