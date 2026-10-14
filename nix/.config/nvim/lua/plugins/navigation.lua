return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
      require('telescope').setup({
        defaults = {
          preview = { timeout = 150, filesize_limit = 1 },
        },
        pickers = {
          live_grep = {
            debounce = 120,
            additional_args = function() return { '--max-columns=200' } end,
          },
          find_files = {
            debounce = 60,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
          },
        },
      })
      pcall(require('telescope').load_extension, 'fzf')
    end,
  },
  {
    "junegunn/fzf",
    build = "./install --all"
  },
}
