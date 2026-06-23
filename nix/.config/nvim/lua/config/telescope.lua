local builtin = require('telescope.builtin')

vim.keymap.set('n', '<C-p>', function()
  builtin.find_files({
    hidden = true,
    file_ignore_patterns = { '%.git/' },
  })
end, { desc = 'Telescope find files (incl. hidden & ignored)' })

vim.keymap.set('n', '<leader>fg', function()
  builtin.live_grep({ additional_args = { '--hidden', '--glob', '!.git/' } })
end, { desc = 'Telescope live grep' })

vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
