local profile = require("config.profile")

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
        cell = "trimmed",
      },
    },
    keys = {
      {
        profile.is_thin and "<leader>mr" or "<leader>m",
        "<cmd>RenderMarkdown toggle<cr>",
        desc = "Toggle Markdown render",
      },
    },
  },
}
