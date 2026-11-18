return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSend", "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny" },
  },
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    keys = {
      { "<leader>oa", mode = { "n", "x" }, function() require("opencode").ask("@this: ") end, desc = "Ask opencode" },
      { "<leader>os", mode = { "n", "x" }, function() require("opencode").select() end, desc = "Execute opencode action" },
      { "<leader>oo", mode = { "n", "x" }, function() require("opencode").operator("@this ") end, expr = true, desc = "Add range to opencode" },
      { "<S-C-u>", mode = { "n" }, function() require("opencode").command("session.half.page.up") end, desc = "Scroll opencode up" },
      { "<S-C-d>", mode = { "n" }, function() require("opencode").command("session.half.page.down") end, desc = "Scroll opencode down" },
    },
    dependencies = {
      {
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {},
          picker = {
            actions = {
              opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
            },
            win = {
              input = {
                keys = {
                  ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
                },
              },
            },
          },
        },
      },
    },
    config = function()
      vim.g.opencode_opts = {
        server = {
          start = false,
        },
      }
      vim.o.autoread = true
    end,
  }
}
