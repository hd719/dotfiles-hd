-- lazy.nvim must install itself before it can manage the other plugins. Read
-- its exact version from lazy-lock.json so a fresh machine matches existing ones.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"

-- `pcall` turns a Lua error into `(false, error)`, letting this file replace a
-- low-level read failure with a clear lockfile-specific message.
local read_ok, lines = pcall(vim.fn.readfile, lockfile)
if not read_ok then
  error("Failed to read " .. lockfile)
end

-- Decode separately so malformed JSON gets the same clear, early failure as a
-- missing lazy.nvim entry instead of starting with an unknown plugin version.
local decode_ok, lock = pcall(vim.json.decode, table.concat(lines, "\n"))
if not decode_ok or type(lock["lazy.nvim"]) ~= "table" then
  error("Missing or invalid lazy.nvim entry in " .. lockfile)
end

local lazy_commit = lock["lazy.nvim"].commit
local lazy_branch = lock["lazy.nvim"].branch
if type(lazy_commit) ~= "string" or type(lazy_branch) ~= "string" then
  error("Missing lazy.nvim branch or commit in " .. lockfile)
end

-- This helper does not throw. Git's exit status becomes a Lua boolean, and its
-- trimmed output can be compared directly with a commit hash.
local function try_git(args)
  local output = vim.fn.system(args)
  return vim.v.shell_error == 0, vim.trim(output)
end

-- Required Git steps use this strict wrapper so Neovim stops instead of
-- continuing with a partial or unknown lazy.nvim installation.
local function run_git(args, failure_message)
  local ok, output = try_git(args)
  if not ok then
    error(failure_message .. "\n" .. output)
  end

  return output
end

-- lazy.nvim cannot install itself. Clone it only when its data directory is
-- absent; reruns reuse and verify the existing checkout below.
if not vim.uv.fs_stat(lazypath) then
  run_git({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=" .. lazy_branch,
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }, "Failed to install lazy.nvim")
end

-- Keep the checkout at the locked commit. Try local Git objects first; if the
-- commit is missing, fetch its branch and retry. Detached HEAD prevents a moving
-- branch tip from silently changing the installed version.
if lazy_commit then
  local current_commit =
    run_git({ "git", "-C", lazypath, "rev-parse", "HEAD" }, "Failed to inspect lazy.nvim")
  if current_commit ~= lazy_commit then
    local checkout_ok = try_git({ "git", "-C", lazypath, "checkout", "--detach", lazy_commit })
    if not checkout_ok then
      run_git(
        { "git", "-C", lazypath, "fetch", "--filter=blob:none", "origin", lazy_branch },
        "Failed to fetch the locked lazy.nvim branch"
      )
      run_git(
        { "git", "-C", lazypath, "checkout", "--detach", lazy_commit },
        "Failed to restore the locked lazy.nvim commit"
      )
    end
  end
end

-- Add lazy.nvim to Neovim's module search path so `require("lazy")` can find it.
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- Import the plugin specifications stored under lua/plugins/.
    { import = "plugins" },
  },
  install = {
    colorscheme = { "nord", "habamax" },
  },
  checker = {
    enabled = false,
  },
  change_detection = {
    notify = false,
  },
  rocks = {
    enabled = false,
  },
  ui = {
    border = "rounded",
  },
})
