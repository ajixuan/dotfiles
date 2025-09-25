
local on_attach = function(client, bufnr)
  -- Mappings
  local map = vim.keymap.set
  -- Diagnostic
  map("n", "gn", vim.diagnostic.goto_next, {desc = "Go to next diagnostics"})
  map("n", "gb", vim.diagnostic.goto_prev, {desc = "Go to prev diagnostics"})
  map("n", "ge", vim.diagnostic.open_float, {desc = "Show diagnostics"})

  -- Buffer
  map('n', 'gd', vim.lsp.buf.definition, {desc ='[LSP] Go to Definition'})
  map('n', 'gD', vim.lsp.buf.declaration, {desc ='[LSP] Go to Declaration'})
  map('n', 'gr', vim.lsp.buf.references, {desc = '[LSP] References'})
  map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Go to type definition"})
end

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

