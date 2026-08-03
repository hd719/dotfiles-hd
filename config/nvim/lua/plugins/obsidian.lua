local vault = vim.fn.expand("~/Developer/hd")
local daily_template = vim.fn.stdpath("config") .. "/templates/private-daily.md"

local function adjacent_day(context, offset)
  local note_id = context.partial_note and context.partial_note.id or os.date("%Y-%m-%d")
  local year, month, day = note_id:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

  return os.date(
    "%Y-%m-%d",
    os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day) + offset,
      hour = 12,
    })
  )
end

local function export_pdf()
  local path = vim.api.nvim_buf_get_name(0)
  local relative_path = vim.fs.relpath(vault, path)

  if vim.bo.filetype ~= "markdown" or relative_path == nil then
    vim.notify("Open a Markdown note in the hd vault before exporting to PDF", vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    local ok, err = pcall(vim.cmd.update)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
  end

  local uri = ("obsidian://adv-uri?vault=hd&filepath=%s&commandid=workspace%%3Aexport-pdf"):format(
    vim.uri_encode(relative_path, "rfc2396")
  )
  local _, err = vim.ui.open(uri)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cond = function()
      return vim.env.DOTFILES_NVIM_RESTORE_ALL == "1"
        or vim.fn.isdirectory(vault .. "/.obsidian") == 1
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
      daily_notes = {
        folder = "Knowledge/_private/daily",
        date_format = "YYYY-MM-DD",
        template = daily_template,
        default_tags = { "private", "daily" },
        workdays_only = false,
      },
      templates = {
        substitutions = {
          yesterday = function(context)
            return adjacent_day(context, -1)
          end,
          tomorrow = function(context)
            return adjacent_day(context, 1)
          end,
        },
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
      { "<leader>od", "<cmd>Obsidian today<cr>", desc = "Today's daily note" },
      { "<leader>oo", "<cmd>Obsidian open<cr>", desc = "Open note in Obsidian" },
      { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "Tags" },
      { "<leader>op", export_pdf, desc = "Export note to PDF" },
      { "<leader>oc", "<cmd>Obsidian toc<cr>", desc = "Table of contents" },
      { "<leader>oma", vim.lsp.buf.code_action, desc = "Marksman actions" },
      {
        "<leader>omd",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Marksman definition",
      },
      {
        "<leader>omh",
        function()
          vim.lsp.buf.hover({ border = "rounded" })
        end,
        desc = "Marksman hover",
      },
      {
        "<leader>omm",
        "<cmd>MarksmanDiagnosticsToggle<cr>",
        desc = "Marksman diagnostics",
      },
      { "<leader>omn", vim.lsp.buf.rename, desc = "Marksman rename" },
      {
        "<leader>omr",
        function()
          Snacks.picker.lsp_references()
        end,
        desc = "Marksman references",
      },
      {
        "<leader>oms",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "Marksman symbols",
      },
    },
  },
}
