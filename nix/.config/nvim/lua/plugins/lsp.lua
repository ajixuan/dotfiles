return {
  {
    "neovim/nvim-lspconfig", -- REQUIRED: for native Neovim LSP integration
    lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
    dependencies = {
      -- main one
      { "ms-jpq/coq_nvim", branch = "coq" },

      -- 9000+ Snippets
      { "ms-jpq/coq.artifacts", branch = "artifacts" },

      -- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
      -- Need to **configure separately**
      { 'ms-jpq/coq.thirdparty', branch = "3p" }
      -- - shell repl
      -- - nvim lua api
      -- - scientific calculator
      -- - comment banner
      -- - etc
    },
    opts = {

    },
    init = function()
      vim.g.coq_settings = {
          -- start coq at startup
          auto_start = 'shut-up',

          keymap = {
            jump_to_mark = '',
          }
      }
    end,
    config = function()
      vim.lsp.enable('gopls')
      vim.keymap.set("n", "gn", vim.diagnostic.goto_next, {desc = "Go to next diagnostics"})
      vim.keymap.set("n", "gb", vim.diagnostic.goto_prev, {desc = "Go to prev diagnostics"})
      vim.keymap.set("n", "ge", vim.diagnostic.open_float, {desc = "Show diagnostics"})
    end,
  }
}
