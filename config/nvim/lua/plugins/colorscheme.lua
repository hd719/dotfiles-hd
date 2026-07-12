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
        highlights.FloatBorder.fg = colors.frost.ice

        -- Match Zed's readable comment tone without losing Nord's italics.
        highlights.Comment.fg = "#B5B5B5"
        highlights["@comment"].fg = "#B5B5B5"

        -- Keep relative numbers visible while the current line stays brightest.
        for _, group in ipairs({ "LineNr", "LineNrAbove", "LineNrBelow" }) do
          highlights[group] = vim.tbl_extend("force", highlights[group] or {}, {
            fg = colors.frost.artic_water,
            bg = colors.none,
          })
        end
      end,
    },
    config = function(_, opts)
      require("nord").setup(opts)
      vim.cmd.colorscheme("nord")
    end,
  },
}
