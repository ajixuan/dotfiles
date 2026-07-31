local M = { backend = "claude" }

local backends = {
  claude = {
    toggle = function() vim.cmd("ClaudeCode") end,
    send   = function() vim.cmd("ClaudeCodeSend") end,
    ask    = function() vim.cmd("ClaudeCodeFocus") end,
    accept = function() vim.cmd("ClaudeCodeDiffAccept") end,
    deny   = function() vim.cmd("ClaudeCodeDiffDeny") end,
  },
  opencode = {
    toggle = function() require("opencode").command("session.toggle") end,
    send   = function() require("opencode").operator("@this ") end,
    ask    = function() require("opencode").ask("@this: ") end,
    accept = function() vim.notify("accept: not supported by opencode", vim.log.levels.WARN) end,
    deny   = function() vim.notify("deny: not supported by opencode", vim.log.levels.WARN) end,
  },
}

local function call(op)
  local b = backends[M.backend]
  if not b or not b[op] then
    vim.notify("AI: no " .. op .. " for backend " .. M.backend, vim.log.levels.WARN)
    return
  end
  b[op]()
end

vim.keymap.set({ "n", "v" }, "<leader>at", function() call("toggle") end, { desc = "AI toggle" })
vim.keymap.set({ "n", "v" }, "<leader>as", function() call("send") end,   { desc = "AI send selection" })
vim.keymap.set({ "n", "v" }, "<leader>aa", function() call("ask") end,    { desc = "AI ask" })
vim.keymap.set("n",         "<leader>ay", function() call("accept") end,  { desc = "AI accept diff" })
vim.keymap.set("n",         "<leader>an", function() call("deny") end,    { desc = "AI deny diff" })

vim.keymap.set("n", "<leader>ab", function()
  vim.ui.select(vim.tbl_keys(backends), { prompt = "AI backend:" }, function(choice)
    if choice then
      M.backend = choice
      vim.notify("AI backend → " .. choice)
    end
  end)
end, { desc = "AI: switch backend" })

return M
