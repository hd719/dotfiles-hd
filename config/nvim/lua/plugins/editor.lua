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
    -- Lazy calls `build` after installing or updating the plugin. Tree-sitter
    -- returns an asynchronous task, so wait before reporting a successful build.
    build = function()
      assert(require("nvim-treesitter").update():wait(300000))
    end,
    config = function()
      -- Interactive startup installs parsers in the background. The bootstrap
      -- sets this flag and waits up to five minutes so headless setup cannot
      -- finish before the required parsers are ready.
      local install_task = require("nvim-treesitter").install(parsers)
      if vim.env.DOTFILES_NVIM_BOOTSTRAP == "1" then
        assert(install_task:wait(300000))
      end

      vim.api.nvim_create_autocmd("FileType", {
        desc = "Enable Tree-sitter highlighting when a parser is installed",
        pattern = filetypes,
        callback = function()
          -- A missing parser should not stop the file from opening. `pcall`
          -- contains that expected error; highlighting starts when possible.
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
