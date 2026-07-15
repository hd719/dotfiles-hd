return {
  -- Auto-close brackets, quotes, and other pairs while typing.
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Add, change, and delete surrounding pairs (quotes, brackets, tags).
  -- Uses a `gs` prefix so the native `s` (substitute) key is preserved.
  {
    "nvim-mini/mini.surround",
    keys = {
      { "gsa", mode = { "n", "x" }, desc = "Surround add" },
      { "gsd", desc = "Surround delete" },
      { "gsr", desc = "Surround replace" },
      { "gsf", desc = "Surround find right" },
      { "gsF", desc = "Surround find left" },
      { "gsh", desc = "Surround highlight" },
    },
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
      },
    },
  },
}
