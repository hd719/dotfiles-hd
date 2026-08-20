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
        linebreak = true,
      },
    },
  },
}
