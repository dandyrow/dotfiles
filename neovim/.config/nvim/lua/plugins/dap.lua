return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    -- Link to docs: https://github.com/mfussenegger/nvim-dap
    local dap = require("dap")
    local dapui = require("dapui")

    ---@diagnostic disable: missing-fields
    dapui.setup({
      icons = { expanded = "", collapsed = "", current_frame = "󰛄" },
      controls = {
        icons = {
          pause = "󰏤",
          play = "▶",
          step_into = "",
          step_over = "",
          step_out = "",
          step_back = "",
          run_last = "▶▶",
          terminate = "",
          disconnect = "󰇪",
        },
      },
    })
    ---@diagnostic enable: missing-fields

    local breakpoint_icons =
      { Breakpoint = "●", BreakpointCondition = "", BreakpointRejected = "⊘", LogPoint = "", Stopped = "" }
    for type, icon in pairs(breakpoint_icons) do
      local tp = "Dap" .. type
      vim.fn.sign_define(tp, { text = icon, texthl = tp, numhl = tp })
    end

    dap.listeners.after.event_initialized["dapui_config"] = dapui.open
    dap.listeners.before.event_terminated["dapui_config"] = dapui.close
    dap.listeners.before.event_exited["dapui_config"] = dapui.close

    require("plugins.dap.adapters")
    require("plugins.dap.configurations")
  end,
  ensure_installed = {
    "codelldb",
    "bash-debug-adapter",
  },
  keys = {
    {
      "<leader>dc",
      function()
        require("dap").continue()
      end,
      desc = "Debug: start/continue",
    },
    {
      "<leader>di",
      function()
        require("dap").step_into()
      end,
      desc = "Debug: step into",
    },
    {
      "<leader>do",
      function()
        require("dap").step_over()
      end,
      desc = "Debug: step over",
    },
    {
      "<leader>dO",
      function()
        require("dap").step_out()
      end,
      desc = "Debug: step out",
    },
    {
      "<leader>db",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "Debug: toggle breakpoint",
    },
    {
      "<leader>dB",
      function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
      desc = "Debug: Set Breakpoint",
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      "<leader>dr",
      function()
        require("dapui").toggle()
      end,
      desc = "Debug: See last session result.",
    },
  },
}
