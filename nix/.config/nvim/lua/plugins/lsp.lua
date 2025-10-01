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
        virtual_lines = true,
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
  }
}
