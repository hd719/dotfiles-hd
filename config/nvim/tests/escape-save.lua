vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load the real keymap module, which registers the Escape mapping as a side effect.
dofile(vim.fn.getcwd() .. "/config/nvim/lua/config/keymaps.lua")

-- Pull out the Normal-mode Escape callback so each test can call the save logic
-- directly instead of trying to simulate keyboard input.
local escape_callback
for _, mapping in ipairs(vim.api.nvim_get_keymap("n")) do
  if mapping.lhs == "<Esc>" then
    escape_callback = mapping.callback
    break
  end
end

assert(type(escape_callback) == "function", "Normal-mode Escape callback was not found")

-- Read the file on disk. Buffer text alone cannot prove that a write happened.
local function read_file(path)
  local file = assert(io.open(path, "r"))
  local contents = file:read("*a")
  file:close()
  return contents
end

-- Give each case a fresh temporary file and buffer. `pcall` captures a test
-- failure so cleanup still runs; the final assert then reports that failure.
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

-- An API edit outside the InsertEnter/InsertLeave events models a Normal-mode edit.
local function set_text(buf, text)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
end

-- Fire the same events as an Insert session. Omitting `text` models entering and
-- leaving Insert mode without changing the buffer.
local function insert_session(buf, text)
  vim.api.nvim_exec_autocmds("InsertEnter", { buffer = buf })
  if text then
    set_text(buf, text)
  end
  vim.api.nvim_exec_autocmds("InsertLeave", { buffer = buf })
end

-- A Normal-mode-only edit is never authorized for Escape-to-save.
with_file(function(buf, path)
  set_text(buf, "normal edit")
  escape_callback()
  assert(read_file(path) == "base\n", "Normal-mode edit was written")
  assert(vim.bo[buf].modified, "Normal-mode edit should remain unsaved")
end)

-- A real Insert-mode edit is authorized and written on the next Escape.
with_file(function(buf, path)
  insert_session(buf, "insert edit")
  escape_callback()
  assert(read_file(path) == "insert edit\n", "Insert-mode edit was not written")
  assert(not vim.bo[buf].modified, "Saved Insert-mode edit should be clean")
end)

-- Consecutive Insert sessions may extend the same authorized edit.
with_file(function(buf, path)
  insert_session(buf, "first insert edit")
  insert_session(buf, "second insert edit")
  escape_callback()
  assert(
    read_file(path) == "second insert edit\n",
    "Consecutive Insert-mode edits were not written"
  )
  assert(not vim.bo[buf].modified, "Saved consecutive Insert-mode edits should be clean")
end)

-- A later empty Insert session disarms the authorization from the earlier edit.
with_file(function(buf, path)
  insert_session(buf, "insert edit")
  insert_session(buf)
  escape_callback()
  assert(read_file(path) == "base\n", "Empty Insert session preserved earlier authorization")
  assert(vim.bo[buf].modified, "Insert edit should remain unsaved after an empty session")
end)

-- A Normal-mode edit between Insert sessions makes the earlier token stale.
with_file(function(buf, path)
  insert_session(buf, "first insert edit")
  set_text(buf, "normal edit")
  insert_session(buf, "second insert edit")
  escape_callback()
  assert(read_file(path) == "base\n", "Normal edit between Insert sessions was written")
  assert(vim.bo[buf].modified, "Mixed edits should remain unsaved")
end)

-- An empty Insert session cannot authorize a pre-existing Normal-mode edit.
with_file(function(buf, path)
  set_text(buf, "normal edit")
  insert_session(buf)
  escape_callback()
  assert(read_file(path) == "base\n", "Empty Insert session armed a Normal-mode edit")
  assert(vim.bo[buf].modified, "Normal-mode edit should remain unsaved")
end)

-- Undo followed by a Normal-mode edit must invalidate the old Insert token.
with_file(function(buf, path)
  insert_session(buf, "insert edit")
  vim.cmd.undo()
  set_text(buf, "normal edit")
  escape_callback()
  assert(read_file(path) == "base\n", "Stale Insert authorization wrote a later Normal-mode edit")
  assert(vim.bo[buf].modified, "Later Normal-mode edit should remain unsaved")
end)

-- Insert mode cannot authorize a buffer that was already dirty from Normal mode.
with_file(function(buf, path)
  set_text(buf, "normal edit")
  insert_session(buf, "normal plus insert edit")
  escape_callback()
  assert(read_file(path) == "base\n", "Insert edit wrote a buffer that was already modified")
  assert(vim.bo[buf].modified, "Mixed Normal/Insert edits should require a manual write")
end)

print("escape-save regression tests: ok")
