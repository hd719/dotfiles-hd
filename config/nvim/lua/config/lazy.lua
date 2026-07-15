local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
local read_ok, lines = pcall(vim.fn.readfile, lockfile)
if not read_ok then
  error("Failed to read " .. lockfile)
end

local decode_ok, lock = pcall(vim.json.decode, table.concat(lines, "\n"))
if not decode_ok or type(lock["lazy.nvim"]) ~= "table" then
  error("Missing or invalid lazy.nvim entry in " .. lockfile)
end

local lazy_commit = lock["lazy.nvim"].commit
local lazy_branch = lock["lazy.nvim"].branch
if type(lazy_commit) ~= "string" or type(lazy_branch) ~= "string" then
  error("Missing lazy.nvim branch or commit in " .. lockfile)
end

local function try_git(args)
  local output = vim.fn.system(args)
  return vim.v.shell_error == 0, vim.trim(output)
end

local function run_git(args, failure_message)
  local ok, output = try_git(args)
  if not ok then
    error(failure_message .. "\n" .. output)
  end

  return output
end

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

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
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
