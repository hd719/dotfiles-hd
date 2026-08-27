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

  if refreshed == 0 and vim.bo.filetype == "markdown" then
    vim.cmd("MarkdownTableRefresh")
  elseif refreshed == 0 then
    vim.notify("No active Markdown table reader", vim.log.levels.INFO)
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
