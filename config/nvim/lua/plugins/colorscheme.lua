return {
  {
    "gbprod/nord.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      terminal_colors = true,
      on_highlights = function(highlights, colors)
        highlights.NormalFloat.bg = colors.none
        highlights.FloatBorder.bg = colors.none
      end,
    },
    config = function(_, opts)
      require("nord").setup(opts)
      vim.cmd.colorscheme("nord")
    end,
  },
}
