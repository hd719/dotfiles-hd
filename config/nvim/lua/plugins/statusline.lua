return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-mini/mini.icons",
    },
    event = "VeryLazy",
    config = function()
      -- Reuse mini.icons as the devicons provider (same as bufferline).
      require("mini.icons").mock_nvim_web_devicons()

      -- Compact list of language servers attached to the current buffer.
      local function lsp_clients()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          return ""
        end
        local names = {}
        for _, client in ipairs(clients) do
          names[#names + 1] = client.name
        end
        return " " .. table.concat(names, ",")
      end

      local function position()
        local line = vim.fn.line(".")
        local column = vim.fn.charcol(".")
        local total = math.max(vim.fn.line("$"), 1)
        local progress = math.floor((line / total) * 100)

        -- Statusline text uses '%' as control syntax, so display one literal
        -- percent sign by returning the escaped '%%' sequence.
        return string.format("%d:%d · %d%%%%", line, column, progress)
      end

      local theme = require("lualine.themes.nord")
      theme.normal.c.bg = "NONE"
      theme.inactive.c.bg = "NONE"

      -- Nord's frost teal for Visual differs from the frost blue used for
      -- Normal only in its blue channel, which is indistinguishable once
      -- Modicator reuses it for a single line number. Aurora orange is the
      -- furthest Nord hue from the other four modes.
      theme.visual.a.bg = "#d08770"

      require("lualine").setup({
        options = {
          theme = theme,
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            "branch",
            {
              "diff",
              -- Use Gitsigns' buffer data instead of shelling out to git.
              source = function()
                local gs = vim.b.gitsigns_status_dict
                if gs then
                  return { added = gs.added, modified = gs.changed, removed = gs.removed }
                end
              end,
            },
          },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "diagnostics", lsp_clients, "filetype" },
          lualine_y = {},
          lualine_z = { position },
        },
      })
    end,
  },
  {
    "mawkler/modicator.nvim",
    -- Recolors the cursor line number per mode, reusing lualine's mode colors.
    -- lualine must already be set up for those highlight groups to exist, so it
    -- is declared as a dependency rather than relying on VeryLazy ordering.
    dependencies = {
      "nvim-lualine/lualine.nvim",
    },
    event = "VeryLazy",
    opts = {
      -- Bold every mode so the current line number reads as the cursor anchor,
      -- not just another number tinted a slightly different color.
      highlights = {
        defaults = { bold = true },
      },
    },
    config = function(_, opts)
      local modicator = require("modicator")
      modicator.setup(opts)

      -- Modicator colors the line number from a VimEnter hook, which has
      -- already fired by the time VeryLazy loads it, so the number would stay
      -- uncolored until the first mode change. Color it once up front.
      modicator.set_cursor_line_highlight(modicator.hl_name_from_mode(vim.api.nvim_get_mode().mode))
    end,
  },
}
