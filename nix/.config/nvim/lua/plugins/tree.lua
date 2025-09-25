return {
  {
    'nvim-tree/nvim-tree.lua', version = "*", lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup {
        view = {
          width = 20,
          preserve_window_proportions = true,
        },
        sync_root_with_cwd = true,
        disable_netrw = true,
      }
    end
  }
}
