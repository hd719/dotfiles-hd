return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = {
      "nvim-mini/mini.icons",
    },
    event = "VeryLazy",
    config = function()
      -- Reuse the already-loaded mini.icons as the devicons provider so we do
      -- not add a second icon plugin.
      require("mini.icons").mock_nvim_web_devicons()

      require("bufferline").setup({
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          separator_style = "thin",
          always_show_bufferline = true,
          show_buffer_close_icons = false,
          show_close_icon = false,
          offsets = {
            {
              filetype = "oil",
              text = "Files",
              highlight = "Directory",
              separator = true,
            },
          },
        },
      })
    end,
  },
}
