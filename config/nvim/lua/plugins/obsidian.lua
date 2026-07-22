local vault = vim.fn.expand("~/Developer/hd")

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cond = function()
      return vim.fn.isdirectory(vault .. "/.obsidian") == 1
    end,
    event = { "BufReadPre *.md", "BufNewFile *.md" },
    cmd = { "Obsidian" },
    init = function()
      vim.g.obsidian_default_keymap = false
    end,
    opts = {
      legacy_commands = false,
      workspaces = {
        { name = "hd", path = vault },
      },
      picker = {
        name = "snacks.picker",
        note_mappings = { new = "", insert_link = "" },
        tag_mappings = { tag_note = "", insert_tag = "" },
      },
      frontmatter = { enabled = false },
      completion = { create_new = false },
      link = {
        style = "wiki",
        format = "shortest",
        auto_update = false,
      },
      file = {
        ignore_filters = {
          "Knowledge/_private/**",
          "Knowledge/raw/_work/**",
          "Knowledge/raw/_drawings/**",
        },
      },
      ui = { enable = false },
      footer = { enabled = false },
      sync = { enabled = false },
      checkbox = { create_new = false },
    },
    keys = {
      { "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Quick switch notes" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search notes" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Links from this note" },
      { "<leader>oo", "<cmd>Obsidian open<cr>", desc = "Open note in Obsidian" },
      { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "Tags" },
      { "<leader>oc", "<cmd>Obsidian toc<cr>", desc = "Table of contents" },
    },
  },
}
