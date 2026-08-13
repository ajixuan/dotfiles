local state = {}
local navigating = false

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    if navigating then return end
    local buf = args.buf
    if vim.bo[buf].buftype ~= "" then return end
    if vim.api.nvim_buf_get_name(buf) == "" then return end

    local win = vim.api.nvim_get_current_win()
    local s = state[win] or { list = {}, pos = 0 }
    state[win] = s

    for i = #s.list, s.pos + 1, -1 do s.list[i] = nil end

    if s.list[s.pos] ~= buf then
      table.insert(s.list, buf)
      s.pos = #s.list
    end

    if #s.list > 30 then
      table.remove(s.list, 1)
      s.pos = s.pos - 1
    end
  end,
})

vim.api.nvim_create_autocmd("WinClosed", {
  callback = function(args) state[tonumber(args.match)] = nil end,
})

local function go(step)
  local win = vim.api.nvim_get_current_win()
  local s = state[win]
  if not s then return end
  local i = s.pos + step
  while i >= 1 and i <= #s.list do
    if vim.api.nvim_buf_is_valid(s.list[i]) then
      s.pos = i
      navigating = true
      vim.api.nvim_win_set_buf(win, s.list[i])
      navigating = false
      return
    end
    i = i + step
  end
end

vim.keymap.set("n", "<leader>h", function() go(-1) end, { desc = "Previous file (window history)" })
vim.keymap.set("n", "<leader>l", function() go(1) end,  { desc = "Next file (window history)" })
