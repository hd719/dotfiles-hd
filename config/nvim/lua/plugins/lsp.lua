return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    lazy = false,
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = {
      keymap = {
        preset = "enter",
        ["<C-Space>"] = false,
      },
      cmdline = {
        keymap = {
          preset = "cmdline",
          ["<C-Space>"] = false,
        },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
        },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      fuzzy = {
        implementation = "prefer_rust",
      },
    },
    opts_extend = { "sources.default" },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "saghen/blink.cmp",
      "b0o/schemastore.nvim",
    },
    config = function()
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
            },
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
              },
            },
          },
        },
      })

      vim.lsp.config("vtsls", {
        settings = {
          vtsls = {
            autoUseWorkspaceTsdk = true,
          },
        },
      })

      -- GraphQL. graphql-lsp is an npm tool with no Homebrew formula, so it is
      -- installed to a fixed, node-version-independent prefix and referenced by
      -- absolute path (no PATH edits). See setup/mac-resilience/README.md for
      -- the reproducible install. Scoped to .graphql files; schema-aware
      -- features come from the project's graphql-config (e.g. graphql.config.ts).
      vim.lsp.config("graphql", {
        cmd = {
          vim.fn.expand("~/.local/graphql-lsp/bin/graphql-lsp"),
          "server",
          "-m",
          "stream",
        },
        filetypes = { "graphql" },
      })

      -- JSON with SchemaStore catalogs (package.json, tsconfig.json, etc.).
      -- The jsonls/cssls/html servers ship with vscode-langservers-extracted,
      -- which is already installed for ESLint.
      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      vim.lsp.enable({
        "bashls",
        "cssls",
        "eslint",
        "gopls",
        "graphql",
        "html",
        "jsonls",
        "lua_ls",
        "vtsls",
      })

      vim.diagnostic.config({
        severity_sort = true,
        -- Show the message inline at the end of the line (VSCode/Zed-style), and
        -- name the source when more than one server reports on a line.
        virtual_text = { spacing = 2, source = "if_many" },
        float = {
          border = "rounded",
        },
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>p",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "x" },
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = {
        go = { "gofmt" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        lua = { "stylua" },
        markdown = { "mdformat" },
        python = { "ruff_format" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
    },
  },
}
