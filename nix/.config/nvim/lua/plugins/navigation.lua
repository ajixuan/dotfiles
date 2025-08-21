return {
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
     dependencies = { 'nvim-lua/plenary.nvim' }
  },

  { "nvim-treesitter/nvim-treesitter", tag = 'v0.10.0', lazy = false, build = ":TSUpdate"},
  { "junegunn/fzf", build = "./install --all" },
}
