local source = debug.getinfo(1, "S").source:sub(2)
local config_root = vim.fs.dirname(vim.fs.dirname(source))
local specs = dofile(config_root .. "/lua/plugins/editor.lua")
local treesitter = specs[2]
local original_bootstrap = vim.env.DOTFILES_NVIM_BOOTSTRAP
local installed_parsers
local wait_timeout
local update_wait_timeout
local wait_result = true

package.loaded["nvim-treesitter"] = {
  install = function(parsers)
    installed_parsers = parsers

    return {
      wait = function(_, timeout)
        wait_timeout = timeout
        return wait_result
      end,
    }
  end,
  update = function()
    return {
      wait = function(_, timeout)
        update_wait_timeout = timeout
        return wait_result
      end,
    }
  end,
}

vim.env.DOTFILES_NVIM_BOOTSTRAP = "1"

treesitter.config()
treesitter.build()

assert(vim.tbl_contains(installed_parsers, "go"), "Go parser must be installed")
assert(vim.tbl_contains(installed_parsers, "tsx"), "TSX parser must be installed")
assert(wait_timeout == 300000, "headless parser installation must wait up to five minutes")
assert(update_wait_timeout == 300000, "parser updates must wait up to five minutes")

wait_timeout = nil
vim.env.DOTFILES_NVIM_BOOTSTRAP = nil

treesitter.config()

assert(wait_timeout == nil, "interactive parser installation must stay asynchronous")

wait_result = false
vim.env.DOTFILES_NVIM_BOOTSTRAP = "1"

local install_ok = pcall(treesitter.config)
assert(not install_ok, "failed parser installation must stop bootstrap")

local update_ok = pcall(treesitter.build)
assert(not update_ok, "failed parser update must stop bootstrap")

vim.env.DOTFILES_NVIM_BOOTSTRAP = original_bootstrap
package.loaded["nvim-treesitter"] = nil

print("Tree-sitter install regression tests: ok")
