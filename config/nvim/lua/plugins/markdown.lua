-- A Reader is an `acwrite` buffer, so the AutoReloadFromDisk autocmd skips it
-- and its hidden source buffer never learns that an agent rewrote the file.
-- The Reader rebuilds from that buffer, so without this it redraws stale text.
local function reload_from_disk(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("checktime")
    end)
  end
end

local function refresh_markdown_tables()
  local reader = require("markdown-table-wrap.reader")
  local refreshed = 0
  local seen = {}

  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if not seen[bufnr] and reader.is_reader(bufnr) then
      seen[bufnr] = true
      reload_from_disk(reader.source_bufnr(bufnr))
      if reader.refresh(bufnr) then
        refreshed = refreshed + 1
      end
    end
  end

  if refreshed > 0 then
    return
  end

  if vim.bo.filetype ~= "markdown" then
    vim.notify("No active Markdown table reader", vim.log.levels.INFO)
    return
  end

  -- Inline mode redraws in the source buffer and stays put. With no view open
  -- at all the plugin opens the Reader in this window, and that opened Reader
  -- is the refresh, so the cursor has to follow it. Press `e` to come back.
  reload_from_disk(vim.api.nvim_get_current_buf())
  vim.cmd("MarkdownTableRefresh")
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- Uses the already-installed markdown Tree-sitter parsers and mini.icons.
    dependencies = {
      "nvim-mini/mini.icons",
    },
    ft = { "markdown" },
    opts = {
      heading = {
        width = "block",
        left_pad = 1,
        right_pad = 1,
      },
      pipe_table = {
        enabled = false,
      },
    },
    keys = {
      {
        "<leader>mr",
        "<cmd>RenderMarkdown toggle<cr>",
        desc = "Toggle Markdown render",
      },
    },
  },
  {
    "ice345/markdown-table-wrap.nvim",
    version = "v0.3.0",
    ft = { "markdown" },
    opts = {
      reader = {
        wrap = true,
        linebreak = true,
      },
    },
    keys = {
      {
        "<leader>mR",
        refresh_markdown_tables,
        desc = "Refresh Markdown tables",
      },
    },
  },
}
