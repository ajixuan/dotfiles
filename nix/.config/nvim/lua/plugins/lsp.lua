return {
  {
    "neovim/nvim-lspconfig", -- REQUIRED: for native Neovim LSP integration
    lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
    dependencies = {
      -- main one
      { "ms-jpq/coq_nvim", branch = "coq" },

      -- 9000+ Snippets
      { "ms-jpq/coq.artifacts", branch = "artifacts" },

      -- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
      -- Need to **configure separately**
      { 'ms-jpq/coq.thirdparty', branch = "3p" }
    },
    init = function()

      vim.g.coq_settings = {
          -- start coq at startup
          auto_start = 'shut-up',
          keymap = {
            jump_to_mark = '',
          }
      }

      local on_attach = function(client, bufnr)
        -- Mappings
        local map = vim.keymap.set
        -- Buffer
        map('n', 'gd', vim.lsp.buf.definition, {desc ='[LSP] Go to Definition'})
        map('n', 'gD', vim.lsp.buf.declaration, {desc ='[LSP] Go to Declaration'})
        map('n', 'gr', vim.lsp.buf.references, {desc = '[LSP] References'})
        map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Go to type definition"})
      end

      vim.diagnostic.config({
        virtual_text = true,
      })
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

      vim.keymap.set('n', '<leader>go', vim.diagnostic.open_float, { desc = 'Open floating diagnostic window' })

    end,
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    opts = {},
    init = function(_, opts)
      local refactoring = require('refactoring')
      refactoring.setup(opts)
      vim.keymap.set({ "n", "x" }, "<leader>re", function() return refactoring.refactor('Extract Function') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rf", function() return refactoring.refactor('Extract Function To File') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rv", function() return refactoring.refactor('Extract Variable') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rI", function() return refactoring.refactor('Inline Function') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>ri", function() return refactoring.refactor('Inline Variable') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rbb", function() return refactoring.refactor('Extract Block') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rbf", function() return refactoring.refactor('Extract Block To File') end, { expr = true })
      vim.keymap.set({ "n", "x" }, "<leader>rr", function() return refactoring.select_refactor() end, { expr = true })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    tag = 'v0.10.0',
    build = ":TSUpdate",
    dependencies = {
      'OXY2DEV/markview.nvim',
      'windwp/nvim-ts-autotag',
    },

    -- NOTE
    -- We cannot use opts here, because someone decided to call config configs
    -- so the only way is to call configs explicitly in config function
    config = function()
      require('nvim-ts-autotag').setup()
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

        autotag = {
          enable = true
        },

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
    opts = {
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "go" },
        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
        auto_install = true,
        autotag = {
          enable = true,
        }
    }
  },
  {
    "m4xshen/autoclose.nvim",
    init = function(_, opts)
      require("autoclose").setup()
    end
  },
}
