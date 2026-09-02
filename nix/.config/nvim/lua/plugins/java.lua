return {
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    dependencies = { "neovim/nvim-lspconfig" },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function()
          local jdtls_cmd = vim.fn.exepath("jdtls")
          if jdtls_cmd == "" then
            vim.notify("jdtls not found in PATH", vim.log.levels.WARN)
            return
          end

          local jdtls = require("jdtls")
          local root_markers = { "gradlew", "mvnw", "pom.xml", "build.gradle", ".git" }
          local root_file = vim.fs.find(root_markers, { upward = true })[1]
          local root_dir = root_file and vim.fs.dirname(root_file) or vim.fn.getcwd()
          local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
          local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

          jdtls.start_or_attach({
            cmd = { jdtls_cmd, "-data", workspace_dir },
            root_dir = root_dir,
            settings = {
              java = {
                signatureHelp = { enabled = true },
                configuration = { updateBuildConfiguration = "interactive" },
                sources = {
                  organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
                },
              },
            },
            on_attach = function(_, bufnr)
              local map = vim.keymap.set
              local opts = { buffer = bufnr }
              map("n", "gd", function() require("telescope.builtin").lsp_definitions() end, opts)
              map("n", "gD", vim.lsp.buf.declaration, opts)
              map("n", "gr", function() require("telescope.builtin").lsp_references() end, opts)
              map("n", "<leader>D", vim.lsp.buf.type_definition, opts)
              map("n", "<leader>jo", jdtls.organize_imports, { buffer = bufnr, desc = "Java: organize imports" })
              map("n", "<leader>jv", jdtls.extract_variable, { buffer = bufnr, desc = "Java: extract variable" })
              map("x", "<leader>jv", function() jdtls.extract_variable(true) end, { buffer = bufnr, desc = "Java: extract variable" })
              map("n", "<leader>jc", jdtls.extract_constant, { buffer = bufnr, desc = "Java: extract constant" })
              map("x", "<leader>jm", function() jdtls.extract_method(true) end, { buffer = bufnr, desc = "Java: extract method" })
            end,
          })
        end,
      })
    end,
  },
}
