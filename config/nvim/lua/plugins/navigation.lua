return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      picker = { enabled = true },
      -- Free Snacks modules: big-file performance safety, reference highlighting
      -- for the symbol under the cursor, and indent guides + scope.
      bigfile = { enabled = true },
      words = { enabled = true },
      indent = { enabled = true },
      -- On-demand sidebar tree (Space e). Keep replace_netrw false so Oil stays
      -- the directory editor and the explorer never hijacks directory buffers.
      explorer = { replace_netrw = false },
      lazygit = {},
      terminal = {},
    },
    keys = {
      {
        "<leader>f",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files",
      },
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "File explorer",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>b",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>S",
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "Project symbols",
      },
      {
        "<leader>cd",
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = "Diagnostics (buffer)",
      },
      {
        "<leader>cD",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics (project)",
      },
      {
        "<leader>d",
        function()
          Snacks.bufdelete()
        end,
        desc = "Close buffer",
      },
      {
        "<leader>g",
        function()
          local source = vim.bo.filetype == "oil" and require("oil").get_current_dir() or 0
          Snacks.lazygit({ cwd = Snacks.git.get_root(source) or vim.fn.getcwd(0) })
        end,
        desc = "LazyGit",
      },
      {
        "gd",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Definitions",
      },
      {
        "<leader>t",
        function()
          Snacks.terminal.open()
        end,
        desc = "New terminal",
      },
      {
        "<leader>T",
        function()
          Snacks.terminal.open(nil, { win = { position = "float" } })
        end,
        desc = "New floating terminal",
      },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = {
      { "nvim-mini/mini.icons", opts = {} },
    },
    opts = {
      view_options = {
        show_hidden = true,
      },
    },
    keys = {
      { "<leader>h", "<cmd>Oil<cr>", desc = "File browser" },
    },
  },
}
