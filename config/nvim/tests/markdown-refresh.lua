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

vim.cmd("MarkdownTableReader")
vim.cmd("MarkdownTableEditSource")
assert(not require("markdown-table-wrap.reader").is_reader(0), "expected Markdown Source mode")
press_refresh("Markdown Source mode")

vim.cmd("MarkdownTableToggleInline")
assert(require("markdown-table-wrap.inline").is_active(0), "expected Markdown Inline mode")
press_refresh("Markdown Inline mode")
vim.cmd("MarkdownTableToggleInline")

vim.cmd("MarkdownTableReader")
assert(require("markdown-table-wrap.reader").is_reader(0), "expected Markdown Reader mode")
vim.cmd("vnew")
press_refresh("a Markdown Reader from another pane")
