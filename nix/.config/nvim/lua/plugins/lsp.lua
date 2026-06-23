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
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
    },
    dependencies = {
      'OXY2DEV/markview.nvim',
    },

    -- NOTE: nvim-treesitter API changed in May 2025
    -- Old API: require'nvim-treesitter.configs'.setup (pre-May 2025)
    -- New API: require'nvim-treesitter'.setup (post-May 2025)
    config = function()
      require'nvim-treesitter'.setup {
        -- A list of parser names, or "all" (the listed parsers MUST always be installed)
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "hcl", "terraform", "bash", "python", "helm", "yaml"  },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        auto_install = true,

        -- List of parsers to ignore installing (or "all")
        ignore_install = { "javascript" },

        -- Directory to install parsers and queries to (prepended to `runtimepath` to have priority)
        install_dir = vim.fn.stdpath('data') .. '/site',
      }

      -- Highlighting is now built-in to Neovim via treesitter
      -- These custom disable rules need to be set via vim.treesitter.language
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
          if not lang then return end

          -- Disable for specific languages
          local disabled_langs = { "c", "rust" }
          if vim.tbl_contains(disabled_langs, lang) then
            vim.treesitter.stop(buf)
            return
          end

          -- Disable for large files
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            vim.treesitter.stop(buf)
          end
        end,
      })
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
