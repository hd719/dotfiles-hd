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

      require("lualine").setup({
        options = {
          theme = "nord",
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
          lualine_y = { "encoding" },
          lualine_z = { "location", "progress" },
        },
      })
    end,
  },
}
