local profile = require("config.profile")

local parsers = {
  "bash",
  "ecma",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "graphql",
  "javascript",
  "json",
  "jsx",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

local filetypes = {
  "go",
  "gomod",
  "gosum",
  "gowork",
  "graphql",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "lua",
  "markdown",
  "python",
  "query",
  "sh",
  "toml",
  "typescript",
  "typescriptreact",
  "vim",
  "vimdoc",
  "yaml",
}

local selected_parsers = profile.is_thin and {
  "markdown",
  "markdown_inline",
} or parsers

local selected_filetypes = profile.is_thin and {
  "markdown",
} or filetypes

local which_key_spec = {
  { "<leader><leader>", hidden = true },
  { "<leader>C", group = "Crosshair" },
  { "<leader>f", group = "Find" },
  { "<leader>m", group = "Markdown" },
  { "<leader>o", group = "Obsidian" },
  { "<leader>om", group = "Marksman" },
  { "<leader>u", group = "UI" },
  { "<leader>W", group = "Windows" },
}

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 0,
      preset = "modern",
      spec = which_key_spec,
    },
  },
  {
    "neovim-treesitter/nvim-treesitter",
    name = "nvim-treesitter",
    dependencies = {
      "neovim-treesitter/treesitter-parser-registry",
    },
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install(selected_parsers)

      vim.api.nvim_create_autocmd("FileType", {
        desc = "Enable Tree-sitter highlighting when a parser is installed",
        pattern = selected_filetypes,
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
