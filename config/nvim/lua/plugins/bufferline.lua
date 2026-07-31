local buffer_move_prefix = "<F13>"

return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = {
      "nvim-mini/mini.icons",
    },
    event = "VeryLazy",
    keys = {
      {
        "<leader>Z",
        function()
          require("which-key").show({ keys = buffer_move_prefix, loop = true })
        end,
        desc = "Move buffer with arrows",
      },
      { buffer_move_prefix .. "<Left>", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },
      { buffer_move_prefix .. "<Right>", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
      { "<leader>X", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
    },
    config = function()
      require("which-key").add({ { buffer_move_prefix, group = "Move buffer" } })

      -- Reuse the already-loaded mini.icons as the devicons provider so we do
      -- not add a second icon plugin.
      require("mini.icons").mock_nvim_web_devicons()

      local transparent_highlights = {}
      local stateful_highlights = {
        "close_button",
        "buffer",
        "numbers",
        "diagnostic",
        "hint",
        "hint_diagnostic",
        "info",
        "info_diagnostic",
        "warning",
        "warning_diagnostic",
        "error",
        "error_diagnostic",
        "modified",
        "duplicate",
        "separator",
        "pick",
      }

      for _, name in ipairs(stateful_highlights) do
        for _, state in ipairs({ "", "_visible", "_selected" }) do
          transparent_highlights[name .. state] = { bg = "NONE" }
        end
      end

      for _, name in ipairs({
        "trunc_marker",
        "fill",
        "group_separator",
        "group_label",
        "tab",
        "tab_selected",
        "tab_close",
        "background",
        "tab_separator",
        "tab_separator_selected",
        "indicator_selected",
        "indicator_visible",
        "offset_separator",
      }) do
        transparent_highlights[name] = { bg = "NONE" }
      end

      require("bufferline").setup({
        highlights = transparent_highlights,
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          move_wraps_at_ends = true,
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
