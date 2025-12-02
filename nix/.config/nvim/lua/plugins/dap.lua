return {
  {
    "mfussenegger/nvim-dap",
    recommended = true,
    desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "leoluz/nvim-dap-go",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },

    -- stylua: ignore
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
      { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dR", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dr", function() require("dap").clear_breakpoints() end, desc = "Clear breakpoints" },
      { "<leader>ds", function() require("dap").session() end, desc = "Session" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Close dapui" },
    },

    config = function()
      -- dap configs
      local dap = require('dap')
      local dapui = require('dapui')

      dap.adapters.go = {
        type = "executable",
        command = "dlv",
        args = {"dap"},
      }
      require('dap-go').setup({
        dap_configurations = {
          {
            type = "go",
            request = "launch",
            name = "Debug with args",
            mode = "test",
            program = function()
              local default_dir = vim.fn.expand("%:p:h")
              return vim.fn.input("Test dir: ", default_dir, "dir")
            end,
            args = function()
              local input = vim.fn.input("Test args: ")
              return vim.split(input, " ", { trimempty = true })
            end,
          },
          {
            type = "go",
            request = "launch",
            name = "lolpersist",
            mode = "test",
            program = function()
              local default_dir = vim.fn.expand("%:p:h")
              return vim.fn.input("Test dir: ", default_dir, "dir")
            end,
            console = "integratedTerminal",
          },
        }
      })

      -- Auto-open dapui on debug session start
      dapui.setup()
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
    end
  }
}
