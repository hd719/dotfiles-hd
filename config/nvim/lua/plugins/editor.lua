local parsers = {
  "bash",
  "ecma",
  "go",
  "gomod",
  "gosum",
  "gowork",
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

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
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
      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        desc = "Enable Tree-sitter highlighting when a parser is installed",
        pattern = filetypes,
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
