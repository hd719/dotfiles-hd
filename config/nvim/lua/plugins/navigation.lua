-- Reuse the fastfetch anon logo as the dashboard header. It is resolved from the
-- dotfiles repo via the ~/.config/nvim symlink and has fastfetch's $N color
-- codes stripped. Falls back to a simple title if the file is not found.
local function anon_header()
  local nvim_dir = vim.fn.resolve(vim.fn.stdpath("config"))
  local logo = vim.fs.dirname(nvim_dir) .. "/fastfetch/logo-anon.txt"
  if vim.fn.filereadable(logo) == 1 then
    local lines = vim.fn.readfile(logo)
    for i, line in ipairs(lines) do
      lines[i] = (line:gsub("%$%d+", ""))
    end
    return "\n" .. table.concat(lines, "\n") .. "\n"
  end
  return "NVIM"
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      picker = {
        enabled = true,
        sources = {
          -- Show dotfiles (e.g. .zshrc, .config) in the explorer sidebar so it
          -- matches Oil. Gitignored files stay hidden; press I in the tree to
          -- reveal them, or H to toggle dotfiles back off.
          explorer = { hidden = true, ignored = false, preview = "none" },
        },
      },
      -- Free Snacks modules: big-file performance safety, reference highlighting
      -- for the symbol under the cursor, and indent guides + scope.
      bigfile = { enabled = true },
      words = { enabled = true },
      indent = { enabled = true },
      -- Render images and PDFs directly in supported terminals such as Ghostty.
      -- Keep PDF frames small enough to pass through Herdr's graphics transport.
      image = {
        enabled = true,
        convert = {
          magick = {
            pdf = {
              "-density",
              120,
              "{src}[{page}]",
              "-background",
              "white",
              "-alpha",
              "remove",
              "-trim",
              "-scale",
              "1920x1080>",
            },
          },
        },
      },
      -- On-demand sidebar tree (Space e). Keep replace_netrw false so Oil stays
      -- the directory editor and the explorer never hijacks directory buffers.
      explorer = { replace_netrw = false },
      lazygit = {},
      terminal = {},
      -- Start screen shown when Neovim opens with no file.
      dashboard = {
        enabled = true,
        preset = {
          header = anon_header(),
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = function() Snacks.dashboard.pick("files") end },
            { icon = " ", key = "/", desc = "Find Text", action = function() Snacks.dashboard.pick("live_grep") end },
            { icon = " ", key = "r", desc = "Recent Files", action = function() Snacks.dashboard.pick("oldfiles") end },
            { icon = " ", key = "e", desc = "File Explorer", action = function() Snacks.explorer() end },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "LazyGit", action = function() Snacks.lazygit() end },
            { icon = " ", key = "c", desc = "Config", action = function() Snacks.dashboard.pick("files", { cwd = vim.fn.stdpath("config") }) end },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "recent_files", icon = " ", title = "Recent Files", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
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
