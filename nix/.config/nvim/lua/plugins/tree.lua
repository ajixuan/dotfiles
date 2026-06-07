return {
  {
    'nvim-tree/nvim-tree.lua', version = "*", lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<Tab>", "<cmd>NvimTreeFindFile<cr>", desc = "Find file in tree" },
      {
        "<CR>",
        function()
          require("nvim-tree.api").tree.toggle({ find_file = true, focus = true })
        end,
        desc = "Toggle tree (reveal current file)",
      },
      {
        "<leader><CR>",
        function()
          require("nvim-tree.api").tree.toggle({ find_file = true, focus = true })
        end,
        desc = "Toggle tree (reveal current file)",
      },
    },
    config = function()
      require("nvim-tree").setup {
        view = {
          width = 20,
          preserve_window_proportions = true,
        },
        sync_root_with_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true,
        },
        disable_netrw = true,
        git = {
          ignore = false,
        },
      }
    end
  }
}
