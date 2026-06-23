local M = {}

local keys = {
  { "Find Files",           "<C-p>" },
  { "Live Grep",            "<Space>fg" },
  { "Buffer List",          "<Space>fb" },
  { "File Tree",            "<Tab>" },
  { "LazyGit",              "<Space>lg" },
  { "Format Buffer",        "<Space>n" },
  { "Toggle Terminal",      "<Space>ot" },
  { "Ask OpenCode",         "<Space>oa" },
  { "OpenCode Actions",     "<Space>os" },
  { "Go to Definition",     "gd" },
  { "Find References",      "gr" },
  { "Search & Replace",     "<Space>S" },
  { "Toggle Breakpoint",    "<Space>db" },
  { "Continue Debug",       "<Space>dc" },
  { "Diagnostic Float",     "<Space>go" },
}

function M.show()
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  for _, k in ipairs(keys) do
    table.insert(lines, string.format("  %-25s %s", k[1], k[2]))
  end
  table.insert(lines, "")
  table.insert(lines, "  q / <Esc> close")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modified = false

  vim.api.nvim_set_hl(0, "SplashKey", { fg = "#7dcfff" })
  vim.api.nvim_set_hl(0, "SplashDesc", { fg = "#c0caf5" })
  vim.api.nvim_set_hl(0, "SplashFooter", { fg = "#565f89" })

  for i, line in ipairs(lines) do
    if line:match("close") then
      vim.api.nvim_buf_add_highlight(buf, -1, "SplashFooter", i - 1, 0, -1)
    elseif line:match("%S") then
      vim.api.nvim_buf_add_highlight(buf, -1, "SplashDesc", i - 1, 2, 27)
      vim.api.nvim_buf_add_highlight(buf, -1, "SplashKey", i - 1, 27, -1)
    end
  end

  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":bd!<CR>", { silent = true, nowait = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":bd!<CR>", { silent = true, nowait = true })
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_win_set_option(win, "signcolumn", "no")
  vim.api.nvim_win_set_option(win, "statuscolumn", "")
end

vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    vim.schedule(function()
      if vim.fn.argc(-1) == 0 and #vim.api.nvim_list_wins() == 1 then
        local buf = vim.api.nvim_get_current_buf()
        local cur_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if #cur_lines == 1 and cur_lines[1] == "" then
          M.show()
        end
      end
    end)
  end,
})

return M
