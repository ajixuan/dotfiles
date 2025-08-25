return {
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
     dependencies = { 'nvim-lua/plenary.nvim' }
  },
  { "junegunn/fzf", build = "./install --all" },
}
