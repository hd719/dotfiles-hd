local map = vim.keymap.set

-- Intentional Zed muscle memory. Nonrecursive mappings prevent an i/a loop.
map("n", "i", "a", { desc = "Insert after cursor" })
map("n", "a", "i", { desc = "Insert before cursor" })

-- Kuncheng's Escape-to-save idea, guarded so it only writes when every unsaved
-- change came from Insert mode. Normal-mode edits change the buffer tick and
-- require an explicit Space-w instead.
local function changedtick(buf)
  return vim.api.nvim_buf_get_changedtick(buf)
end

vim.api.nvim_create_autocmd("InsertEnter", {
  desc = "Track whether Escape-to-save is safe for this Insert session",
  callback = function(args)
    local tick = changedtick(args.buf)
    vim.b[args.buf].save_on_esc_insert_tick = tick
    vim.b[args.buf].save_on_esc_insert_safe = not vim.bo[args.buf].modified
      or vim.b[args.buf].save_on_esc_tick == tick
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  desc = "Arm Escape-to-save after a safe Insert-mode edit",
  callback = function(args)
    local tick = changedtick(args.buf)
    local start_tick = vim.b[args.buf].save_on_esc_insert_tick
    local was_safe = vim.b[args.buf].save_on_esc_insert_safe

    if was_safe and start_tick ~= nil and tick ~= start_tick and vim.bo[args.buf].modified then
      vim.b[args.buf].save_on_esc_tick = tick
    elseif not was_safe then
      vim.b[args.buf].save_on_esc_tick = nil
    end

    vim.b[args.buf].save_on_esc_insert_tick = nil
    vim.b[args.buf].save_on_esc_insert_safe = nil
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  desc = "Disarm Escape-to-save once the buffer is written",
  callback = function(args)
    vim.b[args.buf].save_on_esc_tick = nil
    vim.b[args.buf].save_on_esc_insert_tick = nil
    vim.b[args.buf].save_on_esc_insert_safe = nil
  end,
})

map("n", "<Esc>", function()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if
    vim.b[buf].save_on_esc_tick == changedtick(buf)
    and vim.bo.buftype == ""
    and vim.bo.modifiable
    and vim.bo.modified
    and name ~= ""
  then
    vim.cmd.update()
    vim.notify("Saved " .. vim.fn.fnamemodify(name, ":t"), vim.log.levels.INFO)
  end
end, { desc = "Save a file edited in Insert mode" })

map("n", "<C-a>", "ggVG", { desc = "Select all" })
map("n", "H", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })

map("n", "<leader>v", "<cmd>rightbelow vsplit<cr>", { desc = "Split right" })
map("n", "<leader>s", "<cmd>rightbelow split<cr>", { desc = "Split down" })
map("n", "<leader>n", "<cmd>enew<cr>", { desc = "New file" })
map("n", "<leader>r", "<cmd>checktime<cr>", { desc = "Reload files changed on disk" })

local function open_default_app(path)
  local _, err = vim.ui.open(path)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

local function open_pdf(path)
  local bookokrat = vim.fn.exepath("bookokrat")
  if bookokrat == "" then
    vim.notify("Bookokrat is unavailable; opening the PDF in its default app", vim.log.levels.WARN)
    open_default_app(path)
    return
  end

  local directory = vim.fs.dirname(path)
  local command = vim.fn.shellescape(bookokrat) .. " " .. vim.fn.shellescape(path) .. "; exit"
  local workspace = vim.env.HERDR_WORKSPACE_ID

  if vim.env.HERDR_ENV == "1" and workspace and vim.fn.executable("herdr") == 1 then
    vim.system({
      "herdr",
      "tab",
      "create",
      "--workspace",
      workspace,
      "--cwd",
      directory,
      "--label",
      "PDF",
      "--focus",
    }, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          vim.notify(
            "Could not create the Herdr PDF tab: " .. vim.trim(result.stderr or ""),
            vim.log.levels.ERROR
          )
          return
        end

        local ok, response = pcall(vim.json.decode, result.stdout or "")
        local pane = ok and vim.tbl_get(response, "result", "root_pane", "pane_id") or nil
        if not pane then
          vim.notify("Herdr did not return a pane for the PDF viewer", vim.log.levels.ERROR)
          return
        end

        vim.system({ "herdr", "pane", "run", pane, command }, { text = true }, function(run_result)
          if run_result.code ~= 0 then
            vim.schedule(function()
              vim.notify(
                "Could not start Bookokrat: " .. vim.trim(run_result.stderr or ""),
                vim.log.levels.ERROR
              )
            end)
          end
        end)
      end)
    end)
    return
  end

  if vim.fn.has("mac") == 1 and vim.fn.isdirectory("/Applications/Ghostty.app") == 1 then
    vim.system({
      "open",
      "-na",
      "Ghostty.app",
      "--args",
      "--working-directory=" .. directory,
      "-e",
      bookokrat,
      path,
    }, { detach = true })
    return
  end

  vim.notify(
    "Run this in a supported terminal: bookokrat " .. vim.fn.shellescape(path),
    vim.log.levels.WARN
  )
end

vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "*.pdf", "*.PDF" },
  desc = "Open PDFs in Bookokrat instead of rendering them with Snacks",
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    vim.bo[args.buf].buftype = "nofile"
    vim.bo[args.buf].bufhidden = "wipe"
    vim.bo[args.buf].swapfile = false
    vim.bo[args.buf].modifiable = true
    vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, {
      "PDF launch requested.",
      "",
      "j / k       scroll down / up",
      "h / l       previous / next page",
      "+ / -       zoom in / out",
      "z / Z       fit height / width",
      "/           search the PDF",
      "?           open Bookokrat help",
      "q           quit (press n first if NORMAL is shown)",
      "",
      "Space o     reopen the PDF",
      "Space d     close this placeholder buffer",
    })
    vim.bo[args.buf].filetype = "pdf_launcher"
    vim.bo[args.buf].modifiable = false
    vim.bo[args.buf].readonly = true
    vim.bo[args.buf].modified = false

    if #vim.api.nvim_list_uis() > 0 then
      open_pdf(path)
    end
  end,
})

map("n", "<leader>o", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Current buffer has no file", vim.log.levels.WARN)
    return
  end

  if path:lower():sub(-4) == ".pdf" then
    open_pdf(path)
  else
    open_default_app(path)
  end
end, { desc = "Open file externally" })

-- Copy paths to the system clipboard. WhichKey lists these under Space y, so
-- there is nothing to memorize: press Space y and pick.
map("n", "<leader>yp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied path: " .. path)
end, { desc = "Yank file path" })
map("n", "<leader>yd", function()
  local dir = vim.fn.getcwd()
  vim.fn.setreg("+", dir)
  vim.notify("Copied cwd: " .. dir)
end, { desc = "Yank working dir (pwd)" })
map("n", "<leader>yf", function()
  local folder = vim.fn.expand("%:p:h")
  vim.fn.setreg("+", folder)
  vim.notify("Copied folder: " .. folder)
end, { desc = "Yank file folder" })

-- Folding (Tree-sitter). WhichKey lists these under Space z; native za/zM/zR
-- still work too.
map("n", "<leader>za", "za", { desc = "Toggle fold" })
map("n", "<leader>zo", "zR", { desc = "Open all folds" })
map("n", "<leader>zc", "zM", { desc = "Close all folds" })

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>j", "<C-w>j", { desc = "Window down" })
map("n", "<leader>k", "<C-w>k", { desc = "Window up" })
map("n", "<leader>l", "<C-w>l", { desc = "Window right" })

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<leader>x", "<cmd>x<cr>", { desc = "Save and quit" })

map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>cq", "<cmd>cclose<cr>", { desc = "Close quickfix" })
map("n", "gh", function()
  vim.lsp.buf.hover({ border = "rounded" })
end, { desc = "Hover" })

map("x", "<", "<gv", { desc = "Outdent" })
map("x", ">", ">gv", { desc = "Indent" })
map("x", "J", ":move '>+1<cr>gv=gv", { desc = "Move selection down" })
map("x", "K", ":move '<-2<cr>gv=gv", { desc = "Move selection up" })
map("x", "<leader>c", "gc", { remap = true, desc = "Toggle comment" })

-- Shortcat currently captures Ctrl-Space before it reaches Neovim. Keep these
-- mappings as a fallback if that global shortcut changes later.
map({ "n", "i", "x", "s", "o" }, "<C-Space>", "<Esc>", { desc = "Exit or cancel" })
map("c", "<C-Space>", "<C-c>", { desc = "Cancel command" })
map("t", "<C-Space>", [[<C-\><C-n>]], { desc = "Terminal Normal mode" })
