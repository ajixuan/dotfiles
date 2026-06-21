return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*", -- Latest stable release
    keys = {
      { "<leader>oa", mode = { "n", "x" }, function() require("opencode").ask("@this: ") end, desc = "Ask opencode" },
      { "<leader>os", mode = { "n", "x" }, function() require("opencode").select() end, desc = "Execute opencode action" },
      { "go", mode = { "n", "x" }, function() return require("opencode").operator("@this ") end, expr = true, desc = "Add range to opencode" },
      { "goo", mode = { "n" }, function() return require("opencode").operator("@this ") .. "_" end, expr = true, desc = "Add line to opencode" },
      { "<S-C-u>", mode = { "n" }, function() require("opencode").command("session.half.page.up") end, desc = "Scroll opencode up" },
      { "<S-C-d>", mode = { "n" }, function() require("opencode").command("session.half.page.down") end, desc = "Scroll opencode down" },
    },
    dependencies = {
      {
        -- `snacks.nvim` integration is recommended, but optional
        ---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {}, -- Enhances `ask()`
          picker = { -- Enhances `select()`
            actions = {
              opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
            },
            win = {
              input = {
                keys = {
                  ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
                },
              },
            },
          },
        },
      },
    },
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          start = false,
        },
      }

      vim.o.autoread = true -- Required for `opts.events.reload`

      -- Recommended/example keymaps
      vim.keymap.set({ "n", "x" }, "<leader>oa", function() require("opencode").ask("@this: ") end, { desc = "Ask opencode" })
      vim.keymap.set({ "n", "x" }, "<leader>os", function() require("opencode").select() end, { desc = "Execute opencode action" })
      vim.keymap.set({ "n", "x" }, "go",  function() return require("opencode").operator("@this ") end,        { desc = "Add range to opencode", expr = true })
      vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

      vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,   { desc = "Scroll opencode up" })
      vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      log_level = "DEBUG",
      send_code = false,
      interactions =  {
        chat = {
          adapter = {
            name = "opencode_deepseek"
          }
        }

      }
    },
    config = function()
      require("codecompanion").setup({
        adapters = {
          http = {
            copilot = function()
              return require("codecompanion.adapters").extend("copilot", {
                name = "copilot",
                env = {
                  api_key = "cmd: gpg --batch --quiet --decrypt ../llms/copilot.gpg"
                },
              })
            end,
            venice = function()
              return require("codecompanion.adapters").extend("deepseek", {
                name = "venice",
                formatted_name = "Venice",
                features = {
                  text = true,
                  tokens = true,
                  vision = false,
                },
                env = {
                  url = "https://api.venice.ai/api",
                  chat_url = "/v1/chat/completions",
                  api_key = "cmd: gpg --batch --quiet --decrypt ../llms/venice.gpg"
                },
              })
            end,
            opencode_deepseek = function()
              return require("codecompanion.adapters").extend("deepseek", {
                name = "opencode_deepseek",
                formatted_name = "DeepSeek (OpenCode)",
                env = {
                  api_key = "cmd: echo $DEEPSEEK_API_KEY",
                },
              })
            end,
            opencode_claude = function()
              return require("codecompanion.adapters").extend("anthropic", {
                name = "opencode_claude",
                formatted_name = "Claude (OpenCode)",
                env = {
                  url = "https://ia-foundry-coding-prod-eus2.services.ai.azure.com/anthropic/v1",
                  api_key = "cmd: echo $AZURE_ANTHROPIC_API_KEY",
                },
              })
            end,
          }
        },
      })
    end
  }
}

