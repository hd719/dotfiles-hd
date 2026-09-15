-- Self-contained: writes its own fixture so the disk-reload case can rewrite
-- the file underneath an open Reader.
--   nvim --headless -c 'source config/nvim/tests/markdown-refresh.lua' -c 'qa!'

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local path = dir .. "/tables.md"

local function write_fixture(marker)
  vim.fn.writefile({
    "# Tables",
    "",
    "| Key | Value |",
    "| --- | --- |",
    "| a | " .. marker .. " a long cell value that has to wrap inside the reader |",
    "| b | short |",
  }, path)
end

write_fixture("ORIGINAL")
vim.cmd("edit " .. vim.fn.fnameescape(path))
assert(vim.bo.filetype == "markdown", "fixture did not load as Markdown")

local reader = require("markdown-table-wrap.reader")
local inline = require("markdown-table-wrap.inline")

local refresh_events = 0

vim.api.nvim_create_autocmd("User", {
  pattern = "MarkdownTableWrapRendered",
  callback = function()
    refresh_events = refresh_events + 1
  end,
})

local function press_refresh(description)
  refresh_events = 0
  local keys = vim.api.nvim_replace_termcodes("<Space>mR", true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
  assert(
    vim.wait(1000, function()
      return refresh_events > 0
    end),
    "Space m R did not refresh " .. description
  )
end

local function visible()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

-- With no view open the refresh has to leave a Reader on screen. Restoring the
-- source buffer here would throw away the Reader the plugin just opened and
-- make the key a silent no-op.
vim.cmd("MarkdownTableReader")
vim.cmd("MarkdownTableEditSource")
assert(not reader.is_reader(0), "expected Markdown Source mode")
press_refresh("Markdown Source mode")
assert(reader.is_reader(0), "Space m R refreshed Source mode without leaving a Reader on screen")

vim.cmd("MarkdownTableEditSource")
vim.cmd("MarkdownTableToggleInline")
assert(inline.is_active(0), "expected Markdown Inline mode")
press_refresh("Markdown Inline mode")
assert(inline.is_active(0), "Space m R dropped out of Inline mode")
assert(not reader.is_reader(0), "Space m R moved Inline mode into the Reader")
vim.cmd("MarkdownTableToggleInline")

vim.cmd("MarkdownTableReader")
assert(reader.is_reader(0), "expected Markdown Reader mode")
vim.cmd("vnew")
press_refresh("a Markdown Reader from another pane")
assert(not reader.is_reader(0), "Space m R pulled the cursor into the Reader from another pane")
vim.cmd("close")

-- An agent rewriting the file on disk must reach the Reader. The Reader is an
-- `acwrite` buffer, so the AutoReloadFromDisk autocmd skips it and its hidden
-- source buffer stays stale until the refresh runs `checktime` against it.
assert(reader.is_reader(0), "expected to be back in the Reader")
assert(visible():find("ORIGINAL"), "Reader did not show the original table")
write_fixture("REWRITTENBYANAGENT")
press_refresh("a Reader whose file changed on disk")
assert(
  visible():find("REWRITTENBYANAGENT"),
  "Space m R kept showing the table from before the file changed on disk"
)

vim.fn.delete(dir, "rf")
