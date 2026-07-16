local function open_grug_far_float()
  local existing_buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    existing_buffers[buf] = true
  end

  local width = math.min(110, math.max(20, vim.o.columns - 6))
  local height = math.min(30, math.max(12, vim.o.lines - 8))
  local row = math.max(0, math.floor((vim.o.lines - height - 2) / 2))
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].bufhidden = "hide"

  local win = vim.api.nvim_open_win(scratch, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Replace in current file ",
    title_pos = "center",
    footer = " Space r apply  ·  Space c close  ·  g? help ",
    footer_pos = "center",
    zindex = 50,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      vim.schedule(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local is_new_empty_scratch = not existing_buffers[buf]
            and vim.api.nvim_buf_is_valid(buf)
            and not vim.bo[buf].buflisted
            and vim.bo[buf].buftype == "nofile"
            and vim.api.nvim_buf_get_name(buf) == ""
            and vim.api.nvim_buf_line_count(buf) == 1
            and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""

          if is_new_empty_scratch then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
      end)
    end,
  })

  vim.wo[win].winblend = 0
  vim.wo[win].winhighlight = table.concat({
    "Normal:GrugFarNormal",
    "NormalNC:GrugFarNormal",
    "EndOfBuffer:GrugFarEndOfBuffer",
    "SignColumn:GrugFarNormal",
    "FloatBorder:GrugFarBorder",
    "FloatTitle:GrugFarTitle",
    "FloatFooter:GrugFarFooter",
    "CursorLine:GrugFarCursorLine",
  }, ",")
end

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

  -- Visual search and replace for the current file with a reviewable diff.
  {
    "MagicDuck/grug-far.nvim",
    init = function()
      vim.api.nvim_create_user_command("GrugFarFloat", open_grug_far_float, {
        desc = "Open Grug Far in a centered float",
        force = true,
      })
    end,
    opts = {
      windowCreationCommand = "GrugFarFloat",
      transient = true,
      showCompactInputs = true,
      showInputsTopPadding = false,
      showInputsBottomPadding = false,
      showStatusIcon = false,
      showEngineInfo = false,
      helpLine = {
        enabled = false,
      },
      engines = {
        ripgrep = {
          placeholders = {
            enabled = false,
          },
        },
      },
      folding = {
        enabled = false,
      },
      resultLocation = {
        showNumberLabel = false,
      },
    },
    keys = {
      {
        "<leader>R",
        function()
          local current_file = vim.fn.expand("%:p")
          if current_file == "" then
            vim.notify("Open a named file before replacing", vim.log.levels.WARN)
            return
          end

          if vim.bo.modified then
            vim.notify("Save the current file before replacing", vim.log.levels.WARN)
            return
          end

          local search = vim.fn.expand("<cword>")
          if search == "" then
            vim.notify("Place the cursor on the word to replace", vim.log.levels.WARN)
            return
          end

          local instance = require("grug-far").open({
            prefills = {
              search = search,
              paths = current_file,
              flags = "--fixed-strings --word-regexp",
            },
          })

          instance:when_ready(function()
            local win = vim.fn.bufwinid(instance:get_buf())
            if win ~= -1 then
              vim.wo[win].cursorline = true
            end
            instance:goto_input("replacement")
          end)
        end,
        desc = "Replace word in current file",
      },
    },
  },
}
