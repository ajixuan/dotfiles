return {
  {
    'nvim-tree/nvim-tree.lua', version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<Tab>", function() require("nvim-tree.api").tree.toggle() end, desc = "Toggle file tree" },
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
