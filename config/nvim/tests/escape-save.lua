vim.g.mapleader = " "
vim.g.maplocalleader = " "

dofile(vim.fn.getcwd() .. "/config/nvim/lua/config/keymaps.lua")

local escape_callback
for _, mapping in ipairs(vim.api.nvim_get_keymap("n")) do
  if mapping.lhs == "<Esc>" then
    escape_callback = mapping.callback
    break
  end
end

assert(type(escape_callback) == "function", "Normal-mode Escape callback was not found")

local function read_file(path)
  local file = assert(io.open(path, "r"))
  local contents = file:read("*a")
  file:close()
  return contents
end

local function with_file(run)
  local path = vim.fn.tempname()
  vim.fn.writefile({ "base" }, path)

  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  vim.api.nvim_set_current_buf(buf)

  local ok, err = pcall(run, buf, path)
  vim.api.nvim_buf_delete(buf, { force = true })
  os.remove(path)

  assert(ok, err)
end

local function set_text(buf, text)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
end

local function insert_session(buf, text)
  vim.api.nvim_exec_autocmds("InsertEnter", { buffer = buf })
  if text then
    set_text(buf, text)
  end
  vim.api.nvim_exec_autocmds("InsertLeave", { buffer = buf })
end

with_file(function(buf, path)
  set_text(buf, "normal edit")
  escape_callback()
  assert(read_file(path) == "base\n", "Normal-mode edit was written")
  assert(vim.bo[buf].modified, "Normal-mode edit should remain unsaved")
end)

with_file(function(buf, path)
  insert_session(buf, "insert edit")
  escape_callback()
  assert(read_file(path) == "insert edit\n", "Insert-mode edit was not written")
  assert(not vim.bo[buf].modified, "Saved Insert-mode edit should be clean")
end)

with_file(function(buf, path)
  set_text(buf, "normal edit")
  insert_session(buf)
  escape_callback()
  assert(read_file(path) == "base\n", "Empty Insert session armed a Normal-mode edit")
  assert(vim.bo[buf].modified, "Normal-mode edit should remain unsaved")
end)

with_file(function(buf, path)
  insert_session(buf, "insert edit")
  vim.cmd.undo()
  set_text(buf, "normal edit")
  escape_callback()
  assert(read_file(path) == "base\n", "Stale Insert authorization wrote a later Normal-mode edit")
  assert(vim.bo[buf].modified, "Later Normal-mode edit should remain unsaved")
end)

with_file(function(buf, path)
  set_text(buf, "normal edit")
  insert_session(buf, "normal plus insert edit")
  escape_callback()
  assert(read_file(path) == "base\n", "Insert edit wrote a buffer that was already modified")
  assert(vim.bo[buf].modified, "Mixed Normal/Insert edits should require a manual write")
end)

print("escape-save regression tests: ok")
