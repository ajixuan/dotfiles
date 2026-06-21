return {
  {
    "neovim/nvim-lspconfig", -- REQUIRED: for native Neovim LSP integration
    lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
    init = function()
      local on_attach = function(client, bufnr)
        -- Mappings
        local map = vim.keymap.set
        -- Buffer
        map('n', 'gd', vim.lsp.buf.definition, {desc ='[LSP] Go to Definition'})
        map('n', 'gD', vim.lsp.buf.declaration, {desc ='[LSP] Go to Declaration'})
        map('n', 'gr', vim.lsp.buf.references, {desc = '[LSP] References'})
        map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Go to type definition"})
      end

      vim.lsp.enable('gopls')
      vim.lsp.config('gopls', {
        on_attach = on_attach,
        settings = {
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
          }
        }
      })

      vim.lsp.enable('pyright')
      vim.lsp.config('pyright', {
        on_attach = on_attach,
        settings = {
          python = {
            pythonPath = vim.fn.exepath("python3"),
         }
        }
      })

      vim.lsp.enable('tsserver')
      vim.lsp.config('tsserver', {
        cmd = {'typescript-language-server', '--stdio'},
        filetypes = { 'typescript' },
        root_dir = vim.fs.root(0, {'package.json', '.git'}),
        on_attach = on_attach,
        capabilities = capabilities,
      })

    end,
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    ft = "typescript",
    opts = {},
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "lewis6991/async.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>re", function() return require("refactoring").refactor('Extract Function') end, mode = { "n", "x" }, expr = true, desc = "Extract Function" },
      { "<leader>rf", function() return require("refactoring").refactor('Extract Function To File') end, mode = { "n", "x" }, expr = true, desc = "Extract Function To File" },
      { "<leader>rv", function() return require("refactoring").refactor('Extract Variable') end, mode = { "n", "x" }, expr = true, desc = "Extract Variable" },
      { "<leader>rI", function() return require("refactoring").refactor('Inline Function') end, mode = { "n", "x" }, expr = true, desc = "Inline Function" },
      { "<leader>ri", function() return require("refactoring").refactor('Inline Variable') end, mode = { "n", "x" }, expr = true, desc = "Inline Variable" },
      { "<leader>rbb", function() return require("refactoring").refactor('Extract Block') end, mode = { "n", "x" }, expr = true, desc = "Extract Block" },
      { "<leader>rbf", function() return require("refactoring").refactor('Extract Block To File') end, mode = { "n", "x" }, expr = true, desc = "Extract Block To File" },
      { "<leader>rr", function() return require("refactoring").select_refactor() end, mode = { "n", "x" }, expr = true, desc = "Select refactor" },
    },
    opts = {},
    config = function(_, opts)
      require("refactoring").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      'OXY2DEV/markview.nvim',
    },

    -- NOTE
    -- We cannot use opts here, because someone decided to call config configs
    -- so the only way is to call configs explicitly in config function
    config = function()
      require'nvim-treesitter.configs'.setup {
        -- A list of parser names, or "all" (the listed parsers MUST always be installed)
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "hcl", "terraform", "bash", "python", "helm", "yaml"  },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
        auto_install = true,

        -- List of parsers to ignore installing (or "all")
        ignore_install = { "javascript" },


        ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
        -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

        highlight = {
          enable = true,

          -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
          -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
          -- the name of the parser)
          -- list of language that will be disabled
          disable = { "c", "rust" },
          -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
          disable = function(lang, buf)
              local max_filesize = 100 * 1024 -- 100 KB
              local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
              if ok and stats and stats.size > max_filesize then
                  return true
              end
          end,

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
      }
    end,
  },
  {
    "m4xshen/autoclose.nvim",
    event = "InsertEnter",
    config = function()
      require("autoclose").setup()
    end
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
}
