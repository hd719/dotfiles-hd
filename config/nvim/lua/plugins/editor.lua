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
    build = function()
      assert(require("nvim-treesitter").update():wait(300000))
    end,
    config = function()
      local install_task = require("nvim-treesitter").install(parsers)
      if vim.env.DOTFILES_NVIM_BOOTSTRAP == "1" then
        assert(install_task:wait(300000))
      end

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
