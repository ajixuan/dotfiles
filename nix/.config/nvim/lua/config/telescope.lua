local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-p>', function()
  builtin.find_files({
    hidden = true,
    file_ignore_patterns = { '%.git/' },
    find_command = { "fd", "--no-ignore", "--hidden", "--type", "f" },
  })
end, { desc = 'Telescope find files (incl. hidden & ignored)' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
