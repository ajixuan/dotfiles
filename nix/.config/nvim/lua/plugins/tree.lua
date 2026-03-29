return {
  {
    'nvim-tree/nvim-tree.lua', version = "*", lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>tf", "<cmd>NvimTreeFindFile<cr>", desc = "Find file in tree" },
    },
    config = function()
      require("nvim-tree").setup {
        view = {
          width = 20,
          preserve_window_proportions = true,
        },
        sync_root_with_cwd = true,
        disable_netrw = true,
        git = {
          ignore = false,
        },
      }
    end
  }
}
