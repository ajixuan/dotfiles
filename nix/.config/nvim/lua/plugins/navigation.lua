return {
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
     dependencies = { 'nvim-lua/plenary.nvim' }
  },
  { "nvim-treesitter/nvim-treesitter", branch = 'main', lazy = false, build = ":TSUpdate"},
  { "junegunn/fzf", build = "./install --all" },
}
