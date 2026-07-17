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

        -- Keep Neovim's base tabline transparent when Bufferline has no tabs
        -- to draw, such as while Oil is the only visible buffer.
        for _, group in ipairs({ "TabLine", "TabLineFill", "TabLineSel" }) do
          highlights[group] = vim.tbl_extend("force", highlights[group] or {}, {
            bg = colors.none,
          })
        end

        -- Give the current-file replacement workflow its own calm Nord panel.
        highlights.GrugFarNormal = {
          fg = colors.snow_storm.origin,
          bg = colors.polar_night.origin,
        }
        highlights.GrugFarBorder = {
          fg = colors.frost.ice,
          bg = colors.polar_night.origin,
        }
        highlights.GrugFarTitle = {
          fg = colors.snow_storm.brightest,
          bg = colors.polar_night.origin,
          bold = true,
        }
        highlights.GrugFarFooter = {
          fg = colors.frost.polar_water,
          bg = colors.polar_night.origin,
        }
        highlights.GrugFarEndOfBuffer = {
          fg = colors.polar_night.origin,
          bg = colors.polar_night.origin,
        }
        highlights.GrugFarCursorLine = { bg = colors.polar_night.bright }
        highlights.GrugFarInputLabel = { fg = colors.frost.ice, bold = true }
        highlights.GrugFarInputPlaceholder = {
          fg = "#B5B5B5",
          italic = true,
        }
        highlights.GrugFarResultsHeader = { fg = colors.frost.polar_water }
        highlights.GrugFarResultsStats = { fg = "#B5B5B5" }
        highlights.GrugFarResultsPath = { fg = colors.frost.ice, bold = true }
        highlights.GrugFarResultsMatch = {
          fg = colors.snow_storm.brightest,
          bg = colors.polar_night.brightest,
          bold = true,
        }
        highlights.GrugFarResultsMatchAdded = {
          fg = colors.aurora.green,
          bg = colors.polar_night.bright,
          bold = true,
        }
        highlights.GrugFarResultsMatchRemoved = {
          fg = colors.aurora.red,
          bg = colors.polar_night.bright,
          bold = true,
        }
        highlights.GrugFarResultsChangeIndicator = {
          fg = colors.aurora.yellow,
          bg = colors.none,
        }
        highlights.GrugFarResultsRemoveIndicator = {
          fg = colors.aurora.red,
          bg = colors.none,
        }
        highlights.GrugFarResultsAddIndicator = {
          fg = colors.aurora.green,
          bg = colors.none,
        }

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

        -- Make Gitsigns gutter bars stand out against the transparent
        -- background: green add, cyan change, red delete.
        for group, color in pairs({
          GitSignsAdd = "#a3be8c",
          GitSignsChange = "#88c0d0",
          GitSignsDelete = "#bf616a",
        }) do
          highlights[group] = vim.tbl_extend("force", highlights[group] or {}, {
            fg = color,
            bg = colors.none,
          })
        end

        -- Keep inline blame readable over both light and dark blurred content.
        highlights.GitSignsCurrentLineBlame =
          vim.tbl_extend("force", highlights.GitSignsCurrentLineBlame or {}, {
            fg = "#A7ADB7",
            bg = colors.none,
          })

        -- Let Ghostty's transparent background show through the editor's
        -- current line. The bright line number and cursor still show position.
        highlights.CursorLine = vim.tbl_extend("force", highlights.CursorLine or {}, {
          bg = colors.none,
        })

        -- Keep the Snacks selection visible without overriding icon colors.
        highlights.SnacksPickerListCursorLine = {
          bg = colors.polar_night.brighter,
          bold = true,
        }
      end,
    },
    config = function(_, opts)
      require("nord").setup(opts)
      vim.cmd.colorscheme("nord")
    end,
  },
}
