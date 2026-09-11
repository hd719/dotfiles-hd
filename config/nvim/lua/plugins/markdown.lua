local function refresh_markdown_tables()
  local reader = require("markdown-table-wrap.reader")
  local refreshed = 0
  local seen = {}

  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if not seen[bufnr] and reader.is_reader(bufnr) then
      seen[bufnr] = true
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

  -- Refreshing from the source file must leave the cursor on it. The plugin's
  -- own refresh opens the Reader in the current window, and the Reader is an
  -- unlisted buffer, so Bufferline stops marking the file as current and
  -- getting back to it needs a buffer pick.
  local start_win = vim.api.nvim_get_current_win()
  local start_buf = vim.api.nvim_get_current_buf()

  vim.cmd("MarkdownTableRefresh")

  if vim.api.nvim_win_is_valid(start_win) then
    vim.api.nvim_set_current_win(start_win)
  end
  if vim.api.nvim_buf_is_valid(start_buf) and vim.api.nvim_get_current_buf() ~= start_buf then
    vim.api.nvim_set_current_buf(start_buf)
  end
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
