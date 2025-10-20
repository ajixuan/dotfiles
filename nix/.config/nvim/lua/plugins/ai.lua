return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
    keys = {
      {"<leader>n", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI"}
    },
  },
}

