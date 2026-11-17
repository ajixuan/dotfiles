-- Filetype-specific keymaps.

-- HTML: <leader>br opens the current file in the default browser.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'html',
  callback = function(args)
    vim.keymap.set('n', '<leader>br', function()
      local file = vim.api.nvim_buf_get_name(args.buf)
      if file == '' then
        vim.notify('No file to open', vim.log.levels.WARN)
        return
      end
      vim.fn.jobstart({ 'xdg-open', file }, { detach = true })
    end, { buffer = args.buf, desc = 'Open HTML file in browser' })
  end,
})
