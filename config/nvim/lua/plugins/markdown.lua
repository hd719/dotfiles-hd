return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- Uses the already-installed markdown Tree-sitter parsers and mini.icons.
    dependencies = {
      "nvim-mini/mini.icons",
    },
    ft = { "markdown" },
    opts = {},
    keys = {
      { "<leader>m", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown render" },
    },
  },
}
