return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "mason-org/mason.nvim",
    "jay-babu/mason-nvim-dap.nvim",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    require("mason-nvim-dap").setup({})
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

    dap.adapters.codelldb = {
      type = "executable",
      command = "codelldb",
    }

    dap.configurations.rust = {
      {
        name = "Launch file",
        type = "codelldb",
        request = "launch",
        program = function()
          -- return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          -- Run cargo build before launching
          local build = vim.fn.system("cargo build")
          print(build)

          -- Get binary path
          local handle = io.popen("cargo metadata --format-version 1 --no-deps")
          if not handle then
            error("Failed to run 'cargo metadata'")
          end
          local result = handle:read("*a")
          handle:close()

          local ok, metadata = pcall(vim.fn.json_decode, result)
          if not ok or not metadata then
            error("Failed to parse cargo metadata")
          end

          local target_dir = metadata["target_directory"]
          local package_name = metadata.packages[1].name
          return target_dir .. "/debug/" .. package_name
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      },
    }
  end,
  ensure_installed = {
    "codelldb",
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
