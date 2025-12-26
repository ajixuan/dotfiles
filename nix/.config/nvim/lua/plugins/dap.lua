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
      "mfussenegger/nvim-dap-python",
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
      { "<leader>ds", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Close dapui" },
    },

    config = function()
      -- dap configs
      local dap = require('dap')
      local dapui = require('dapui')

      --table.insert(dap.configurations.python, {
      --    type = 'python';
      --    request = 'launch';
      --    name = "Test File";
      --    module = "unittest";
      --    args = "-v";
      --    pythonPath = function()
      --      return python_path
      --    end;
      --})
      --

      -- Golang
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
  },
  {
      "mfussenegger/nvim-dap-python",
      dependencies = {
        "mfussenegger/nvim-dap"
      },
      keys = {
        { "<Leader>dt", function() require("dap-python").test_method() end, { desc = "Debug nearest test method" }},
      },
      config = function()
        local dap = require('dap')
        local resolve_python = function()
          local venv = os.getenv("VIRTUAL_ENV")
          local python_path = venv and (venv .. "/bin/python") or "python3"
          return python_path
        end

        require("dap-python").setup(resolve_python())
        require("dap-python").test_runner = 'unittest'
        require("dap-python").resolve_python = resolve_python

        table.insert(dap.configurations.python, 1, {
            type = 'python';
            request = 'launch';
            name = "Launch file";
            program = "${file}";
            pythonPath = resolve_python;
        })
      end
  }
}
