return {
  {
    -- Debug adapter install guides:
    -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
    "mfussenegger/nvim-dap",

    keys = {
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Debugger continue",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Debugger step over",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Debugger step into",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "Debugger step out",
      },
      {
        "<leader>dt",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle debugging breakpoint",
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",

    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },

    init = function()
      local dap, dapui = require("dap"), require("dapui")

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,

    config = true,
  },
}
