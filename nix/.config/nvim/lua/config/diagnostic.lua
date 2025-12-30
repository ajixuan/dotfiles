vim.diagnostic.config({virtual_text = true})
vim.keymap.set('n', '<leader>go', vim.diagnostic.open_float, { desc = 'Open floating diagnostic window' })
