-- `debug.getinfo` returns this script's source with a leading `@`; `sub(2)`
-- removes it to make a filesystem path. editor.lua returns a list of plugin
-- specifications, and item 2 is the Tree-sitter specification tested below.
local source = debug.getinfo(1, "S").source:sub(2)
local config_root = vim.fs.dirname(vim.fs.dirname(source))
local specs = dofile(config_root .. "/lua/plugins/editor.lua")
local treesitter = specs[2]
local original_bootstrap = vim.env.DOTFILES_NVIM_BOOTSTRAP
local installed_parsers
local wait_timeout
local update_wait_timeout
local wait_result = true

-- Put a fake module in Lua's module cache. `require("nvim-treesitter")` will use
-- this table, allowing the test to record calls without installing real parsers.
-- A `:` method call passes its table as the first argument; `_` ignores it here.
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

-- Bootstrap mode must wait for both async tasks so a headless setup cannot exit
-- before parser installation and updates finish.
vim.env.DOTFILES_NVIM_BOOTSTRAP = "1"

treesitter.config()
treesitter.build()

assert(vim.tbl_contains(installed_parsers, "go"), "Go parser must be installed")
assert(vim.tbl_contains(installed_parsers, "tsx"), "TSX parser must be installed")
assert(wait_timeout == 300000, "headless parser installation must wait up to five minutes")
assert(update_wait_timeout == 300000, "parser updates must wait up to five minutes")

-- Interactive startup should begin installation without blocking the editor.
wait_timeout = nil
vim.env.DOTFILES_NVIM_BOOTSTRAP = nil

treesitter.config()

assert(wait_timeout == nil, "interactive parser installation must stay asynchronous")

-- Make both fake tasks fail. `pcall` converts the resulting assert errors into
-- false values so the test can prove that bootstrap failures are not swallowed.
wait_result = false
vim.env.DOTFILES_NVIM_BOOTSTRAP = "1"

local install_ok = pcall(treesitter.config)
assert(not install_ok, "failed parser installation must stop bootstrap")

local update_ok = pcall(treesitter.build)
assert(not update_ok, "failed parser update must stop bootstrap")

-- The environment and module cache are process-wide, so restore both after the test.
vim.env.DOTFILES_NVIM_BOOTSTRAP = original_bootstrap
package.loaded["nvim-treesitter"] = nil

print("Tree-sitter install regression tests: ok")
