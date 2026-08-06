local profile = require("config.profile")

return {
  {
    "saghen/blink.cmp",
    enabled = profile.is_full,
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
    dependencies = profile.is_full and {
      "saghen/blink.cmp",
      "b0o/schemastore.nvim",
    } or {},
    config = function()
      if profile.is_full then
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
      end

      local function set_marksman_diagnostics(client_id, bufnr, enabled)
        local namespace = vim.lsp.diagnostic.get_namespace(client_id, false)
        vim.diagnostic.enable(enabled, { bufnr = bufnr, ns_id = namespace })
      end

      vim.api.nvim_create_user_command("MarksmanToggleCurrent", function()
        local bufnr = vim.api.nvim_get_current_buf()
        if not vim.list_contains({ "markdown", "markdown.mdx" }, vim.bo[bufnr].filetype) then
          vim.notify("Marksman can toggle only in a Markdown file", vim.log.levels.WARN)
          return
        end

        local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "marksman" })
        if #clients > 0 then
          for _, client in ipairs(clients) do
            if vim.tbl_count(client.attached_buffers) == 1 then
              client:stop()
            else
              vim.lsp.buf_detach_client(bufnr, client.id)
            end
          end
          vim.notify("Marksman stopped for this file")
          return
        end

        local config = vim.deepcopy(vim.lsp.config.marksman)
        config.root_dir = vim.fs.root(bufnr, config.root_markers or {})
        if vim.lsp.start(config, { bufnr = bufnr, reuse_client = config.reuse_client }) then
          vim.notify("Marksman started for this file")
        end
      end, { desc = "Toggle Marksman for the current Markdown file" })

      vim.api.nvim_create_autocmd("FileType", {
        desc = "Add the per-file Marksman toggle",
        pattern = { "markdown", "markdown.mdx" },
        callback = function(args)
          vim.keymap.set("n", "<leader>mm", "<cmd>MarksmanToggleCurrent<cr>", {
            buffer = args.buf,
            desc = "Toggle Marksman for file",
          })
        end,
      })

      vim.api.nvim_create_user_command("MarksmanDiagnosticsToggle", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "marksman" })
        if #clients == 0 then
          vim.notify("Marksman is not attached to this buffer", vim.log.levels.WARN)
          return
        end

        local namespace = vim.lsp.diagnostic.get_namespace(clients[1].id, false)
        local enabled = not vim.diagnostic.is_enabled({ bufnr = bufnr, ns_id = namespace })
        for _, client in ipairs(clients) do
          set_marksman_diagnostics(client.id, bufnr, enabled)
        end
        vim.notify("Marksman diagnostics " .. (enabled and "shown" or "muted") .. " for this note")
      end, { desc = "Toggle Marksman diagnostics for the current note" })

      if profile.is_full then
        -- GraphQL. graphql-lsp is a Node tool with no Homebrew formula, so pnpm
        -- installs it under a fixed, node-version-independent home and this config
        -- references it by absolute path. See config/nvim/README.md for the
        -- reproducible install. Scoped to .graphql files; schema-aware features
        -- come from the project's graphql-config (e.g. graphql.config.ts).
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
      end

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
    enabled = profile.is_full,
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
