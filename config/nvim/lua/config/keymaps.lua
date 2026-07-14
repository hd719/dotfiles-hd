local map = vim.keymap.set

-- Intentional Zed muscle memory. Nonrecursive mappings prevent an i/a loop.
map("n", "i", "a", { desc = "Insert after cursor" })
map("n", "a", "i", { desc = "Insert before cursor" })

-- Kuncheng's Escape-to-save idea, guarded so it only writes changes actually
-- made in Insert mode. This prevents an accidental Normal-mode edit (a stray
-- `dw`, `x`, paste, etc.) from being silently saved to disk on the next Escape.
-- InsertLeave "arms" the save when the buffer was really edited; any write
-- "disarms" it.
vim.api.nvim_create_autocmd("InsertLeave", {
  desc = "Arm Escape-to-save after a real Insert-mode edit",
  callback = function(args)
    if vim.bo[args.buf].modified then
      vim.b[args.buf].save_on_esc = true
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  desc = "Disarm Escape-to-save once the buffer is written",
  callback = function(args)
    vim.b[args.buf].save_on_esc = false
  end,
})

map("n", "<Esc>", function()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if
    vim.b[buf].save_on_esc
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
