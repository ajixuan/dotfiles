local map = vim.keymap.set

-- Define the on_attach function with key mappings
local on_attach = function(client, bufnr)
  -- Create a helper function for mapping keys
  local function buf_set_keymap(mode, lhs, rhs, desc)
    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
  end

  -- Mappings
  map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', '[LSP] Go to Definition')
  map('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', '[LSP] Go to Declaration')
  map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', '[LSP] References')
  map('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', '[LSP] Rename')
  map('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', '[LSP] Code Action')
  map('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', '[LSP] Prev Diagnostic')
  map('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', '[LSP] Next Diagnostic')
  map('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', '[LSP] Line Diagnostics')
  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
end

vim.lsp.config('gopls', {
  on_attach = on_attach,
  capabilities = vim.lsp.protocol.make_client_capabilities(),
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
