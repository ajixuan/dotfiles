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
    init = function()


      vim.g.coq_settings = {
          -- start coq at startup
          auto_start = 'shut-up',

          keymap = {
            jump_to_mark = '',
          }
      }

      local on_attach = function(client, bufnr)
        -- Mappings
        local map = vim.keymap.set
        -- Buffer
        map('n', 'gd', vim.lsp.buf.definition, {desc ='[LSP] Go to Definition'})
        map('n', 'gD', vim.lsp.buf.declaration, {desc ='[LSP] Go to Declaration'})
        map('n', 'gr', vim.lsp.buf.references, {desc = '[LSP] References'})
        map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Go to type definition"})
      end

      vim.diagnostic.config({
        virtual_text = true,
      })
      vim.lsp.enable('gopls')
      vim.lsp.config('gopls', {
        on_attach = on_attach,
        settings = {
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
          }
        }
      })

    end,
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    opts = {},
    init = function(_, opts)
      local refactoring = require('refactoring')
      refactoring.setup(opts)
      vim.keymap.set({ "n", "x" }, "<leader>re", function() return refactoring.refactor('Extract Function') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rf", function() return refactoring.refactor('Extract Function To File') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rv", function() return refactoring.refactor('Extract Variable') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rI", function() return refactoring.refactor('Inline Function') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>ri", function() return refactoring.refactor('Inline Variable') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rbb", function() return refactoring.refactor('Extract Block') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rbf", function() return refactoring.refactor('Extract Block To File') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rr", function() return refactoring.select_refactor() end, { expr = true })
    end,
  },
  {
    "m4xshen/autoclose.nvim",
    init = function(_, opts)
      require("autoclose").setup()
    end
  }
}
