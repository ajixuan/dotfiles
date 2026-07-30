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
      local dap = require('dap')
      local dapui = require('dapui')

      -- Breakpoint / stopped-line signs
      vim.fn.sign_define('DapBreakpoint',          { text = '●', texthl = 'DiagnosticError', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn',  linehl = '', numhl = '' })
      vim.fn.sign_define('DapLogPoint',            { text = '◆', texthl = 'DiagnosticInfo',  linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped',             { text = '▶', texthl = 'DiagnosticOk',    linehl = 'Visual', numhl = '' })
      vim.fn.sign_define('DapBreakpointRejected',  { text = '○', texthl = 'DiagnosticHint',  linehl = '', numhl = '' })

      -- Inline variable values while stepping
      require('nvim-dap-virtual-text').setup({
        commented = true,
        virt_text_pos = 'eol',
      })

      -- Golang
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
        }
      })

      -- Auto-open dapui on debug session start
      dapui.setup()
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
    end
  },
  {
      "mfussenegger/nvim-dap-python",
      dependencies = {
        "mfussenegger/nvim-dap"
      },
      keys = {
        { "<Leader>dt", function() require("dap-python").test_method({ config = { justMyCode = false } }) end, desc = "Debug nearest test method" },
        { "<Leader>dT", function() require("dap-python").test_class({ config = { justMyCode = false } }) end,  desc = "Debug test class" },
      },
      config = function()
        local dap = require('dap')

        local resolve_python = function()
          local venv = os.getenv("VIRTUAL_ENV")
          if venv then return venv .. "/bin/python" end
          local cwd = vim.fn.getcwd()
          for _, path in ipairs({ cwd .. "/.venv/bin/python", cwd .. "/venv/bin/python" }) do
            if vim.fn.executable(path) == 1 then return path end
          end
          return vim.fn.exepath("python3")
        end

        -- Dedicated debugpy runtime (installed via `pipx install debugpy`).
        -- This decouples debugpy from the project venv — the config's `pythonPath`
        -- still controls which interpreter actually runs the target code.
        local debugpy_python = vim.fn.expand("~/.local/share/pipx/venvs/debugpy/bin/python")
        if vim.fn.executable(debugpy_python) ~= 1 then
          debugpy_python = resolve_python()
        end
        require("dap-python").setup(debugpy_python)
        require("dap-python").test_runner = 'pytest'

        -- Common launch defaults
        local base = {
          type = 'python',
          request = 'launch',
          cwd = "${workspaceFolder}",
          pythonPath = resolve_python,
          justMyCode = false,
          console = "integratedTerminal",
        }
        local function launch(overrides)
          return vim.tbl_extend("force", base, overrides)
        end

        dap.configurations.python = {
          launch({ name = "Launch file",           program = "${file}" }),
          launch({
            name = "Launch file with args",
            program = "${file}",
            args = function() return vim.fn.split(vim.fn.input("Args: ")) end,
          }),
          launch({
            name = "Launch module",
            module = function() return vim.fn.input("Module: ") end,
          }),
          launch({ name = "Pytest: current file",  module = "pytest", args = { "-v", "${file}" } }),
          launch({
            name = "Pytest: with filter",
            module = "pytest",
            args = function()
              local k = vim.fn.input("Pytest -k filter: ")
              return { "-v", "-k", k, "${file}" }
            end,
          }),
          {
            type = 'python',
            request = 'attach',
            name = "Remote Attach (debugpy)",
            connect = function()
              local host = vim.fn.input("Host [127.0.0.1]: ")
              local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
              return { host = host ~= "" and host or "127.0.0.1", port = port }
            end,
            pathMappings = {
              {
                localRoot = "${workspaceFolder}",
                remoteRoot = function()
                  return vim.fn.input("Remote workspace root: ", "/app", "file")
                end,
              },
            },
            justMyCode = false,
          },
        }
      end
  }
}
