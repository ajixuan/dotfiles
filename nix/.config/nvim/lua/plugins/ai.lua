return {
  {
    "olimorris/codecompanion.nvim",
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
            name = "copilot"
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
            end
          }
        },
      })
    end
  },
  {


  }
}

