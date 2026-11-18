return {
  {
    "neovim/nvim-lspconfig", -- REQUIRED: for native Neovim LSP integration
    lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
    init = function()
      local on_attach = function(client, bufnr)
        -- Mappings
        local map = vim.keymap.set
        -- Buffer
        map('n', 'gd', function() require('telescope.builtin').lsp_definitions() end, {desc = '[LSP] Go to Definition'})
        map('n', 'gD', vim.lsp.buf.declaration, {desc ='[LSP] Go to Declaration'})
        map('n', 'gr', function() require('telescope.builtin').lsp_references() end, {desc = '[LSP] References'})
        map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Go to type definition"})
      end

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
      vim.lsp.enable('gopls')

      vim.lsp.config('pyright', {
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          vim.keymap.set("n", "<leader>i", function()
            vim.lsp.buf.code_action({
              context = {
                only = { "quickfix" },
                diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 }),
              },
              apply = true,
              filter = function(action)
                return action.title and action.title:lower():match("import")
              end,
            })
          end, { buffer = bufnr, desc = "Python: auto-import symbol under cursor" })
        end,
        settings = {
          python = {
            pythonPath = vim.fn.exepath("python3"),
         }
        }
      })
      vim.lsp.enable('pyright')

      vim.lsp.config('tsserver', {
        cmd = {'typescript-language-server', '--stdio'},
        filetypes = { 'typescript' },
        root_dir = vim.fs.root(0, {'package.json', '.git'}),
        on_attach = on_attach,
        capabilities = capabilities,
      })
      vim.lsp.enable('tsserver')

      vim.lsp.config('terraformls', {
        cmd = { 'terraform-ls', 'serve' },
        filetypes = { 'terraform', 'terraform-vars', 'hcl' },
        root_dir = vim.fs.root(0, { '.terraform', '.git' }),
        on_attach = on_attach,
        capabilities = capabilities,
      })
      vim.lsp.enable('terraformls')

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
    lazy = false, -- main branch does not support lazy-loading
    build = ":TSUpdate",
    dependencies = {
      'OXY2DEV/markview.nvim',
    },

    -- NOTE: nvim-treesitter API changed in May 2025
    -- Old API: require'nvim-treesitter.configs'.setup with ensure_installed/auto_install/highlight
    -- New API (main branch): require'nvim-treesitter'.install({...}) and per-buffer vim.treesitter.start()
    config = function()
      local ensure = {
        "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
        "hcl", "terraform", "bash", "python", "helm", "yaml",
        "javascript", "typescript", "tsx",
        "java",
      }
      local disabled_langs = { c = true, rust = true }
      local max_filesize = 100 * 1024

      local function start_ts(buf)
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if not lang or disabled_langs[lang] then return end

        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then return end

        local started, err = pcall(vim.treesitter.start, buf, lang)
        if not started then
          vim.notify_once("treesitter highlight failed (" .. lang .. "): " .. tostring(err), vim.log.levels.WARN)
        end
      end

      local function start_all()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
            start_ts(buf)
          end
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args) start_ts(args.buf) end,
      })
      start_all()

      -- Parsers (other than the few bundled with Neovim) are compiled locally.
      -- Without these tools every install fails and highlighting silently
      -- falls back to plain regex syntax, so say so loudly.
      local needed = { "tree-sitter", "cc", "curl", "tar" }
      local absent = vim.tbl_filter(function(exe)
        if exe == "cc" then
          return vim.fn.executable("cc") == 0 and vim.fn.executable("gcc") == 0 and vim.fn.executable("clang") == 0
        end
        return vim.fn.executable(exe) == 0
      end, needed)
      if #absent > 0 then
        vim.notify("nvim-treesitter: missing " .. table.concat(absent, ", ")
          .. " in PATH; parsers can't be installed (tree-sitter-cli >= 0.26.1, not from npm)",
          vim.log.levels.ERROR)
        return
      end

      -- Async; no-op for parsers already installed. Re-attach highlighting
      -- once new parsers land so already-open buffers pick them up.
      require("nvim-treesitter").install(ensure):await(function()
        vim.schedule(start_all)
      end)
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
