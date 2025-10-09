return {
  "folke/snacks.nvim",
  dependencies = { "echasnovski/mini.icons" },
  lazy = false,
  priority = 1000,
  init = function()
    vim.o.statuscolumn = ""
  end,

  opts = {
    dashboard = {
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('smart')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          {
            icon = " ",
            key = "g",
            desc = "Find Text",
            action = ":lua Snacks.dashboard.pick('live_grep', { hidden = true })",
          },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files",
            action = ":lua Snacks.dashboard.pick('oldfiles')",
          },
          {
            icon = " ",
            key = "b",
            desc = "Browse Repo",
            action = function()
              Snacks.gitbrowse()
            end,
            enabled = function()
              return Snacks.git.get_root() ~= nil
            end,
          },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          {
            icon = "󰒲 ",
            key = "L",
            desc = "Lazy",
            action = ":Lazy",
            enabled = package.loaded.lazy ~= nil,
          },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "recent_files", pane = 2, icon = " ", title = "Recent Files", indent = 2, padding = 1 },
        { section = "projects", pane = 2, icon = " ", title = "Projects", indent = 2, padding = 1 },
        { section = "startup" },
      },
    },

    indent = {
      indent = { char = "▏" },
      scope = { underline = true, char = "▏" },
    },

    notifier = { style = "fancy" },

    picker = {
      win = {
        input = {
          keys = {
            ["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
            ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
          },
        },
      },
    },

    statuscolumn = {
      enabled = true,
      folds = { open = true, git_hl = true },
    },

    zen = {
      toggles = { git_signs = false, indent = false },
    },
  },

  keys = {
    {
      "<leader>cn",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Clear notifications from screen",
    },
    {
      "<c-x>",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete buffer",
    },
    {
      "<leader>.",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle scratch buffer",
    },
    {
      "<leader>S",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select bcratch buffer",
    },
    {
      "<leader>gb",
      function()
        Snacks.gitbrowse()
      end,
      desc = "Git browse",
      mode = { "n", "v" },
    },
    {
      "<leader>z",
      function()
        Snacks.zen()
      end,
      desc = "Toggle zen mode",
    },

    ------------
    -- Picker --
    ------------
    {
      "<leader>/",
      function()
        Snacks.picker.grep({ hidden = true, layout = "ivy_split" })
      end,
      desc = "Grep",
    },
    {
      "<leader>:",
      function()
        Snacks.picker.command_history({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Command history",
    },
    {
      "<leader>n",
      function()
        Snacks.picker.notifications({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Notification history",
    },
    {
      '"',
      function()
        Snacks.picker.registers({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Registers",
    },

    -- buffer
    {
      "<leader>b",
      function()
        Snacks.picker.buffers({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Buffer list",
    },

    -- search
    {
      "<leader>sc",
      function()
        Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Config files",
    },
    {
      "<leader>sf",
      function()
        Snacks.picker.smart()
      end,
      desc = "Smart find files",
    },
    {
      "<leader>sg",
      function()
        Snacks.picker.git_files({ untracked = true })
      end,
      desc = "Search git files",
    },
    {
      "<leader>sp",
      function()
        Snacks.picker.projects()
      end,
      desc = "Search projects",
    },
    {
      "<leader>sr",
      function()
        Snacks.picker.recent()
      end,
      desc = "Search recent files",
    },
    {
      "<leader>sw",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Grep visual selection or word under cursor",
      mode = { "n", "x" },
    },
    {
      "<leader>s/",
      function()
        Snacks.picker.search_history()
      end,
      desc = "Search history",
    },
    {
      "<leader>sb",
      function()
        Snacks.picker.lines()
      end,
      desc = "Search buffer lines",
    },
    {
      "<leader>sB",
      function()
        Snacks.picker.grep_buffers()
      end,
      desc = "Grep open buffers",
    },
    {
      "<leader>sC",
      function()
        Snacks.picker.commands()
      end,
      desc = "Search commands",
    },
    {
      "<leader>sd",
      function()
        Snacks.picker.diagnostics_buffer({
          layout = {
            preview = "main",
            preset = "ivy",
          },
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Current buffer diagnostics",
    },
    {
      "<leader>sD",
      function()
        Snacks.picker.diagnostics({
          layout = {
            preview = "main",
            preset = "ivy",
          },
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "All diagnostics",
    },
    {
      "<leader>sh",
      function()
        Snacks.picker.help()
      end,
      desc = "Search help",
    },
    {
      "<leader>si",
      function()
        Snacks.picker.icons()
      end,
      desc = "Search icons",
    },
    {
      "<leader>sm",
      function()
        Snacks.picker.man()
      end,
      desc = "Search man pages",
    },
    {
      "<leader>su",
      function()
        Snacks.picker.undo({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Undo history",
    },
    {
      "<leader>sj",
      function()
        Snacks.picker.jumps({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Jump list",
    },

    -- git
    {
      "<leader>gl",
      function()
        Snacks.picker.git_log({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Git log",
    },
    {
      "<leader>gL",
      function()
        Snacks.picker.git_log_line({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Git log line",
    },
    {
      "<leader>gS",
      function()
        Snacks.picker.git_stash({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Git stash",
    },
    {
      "<leader>gf",
      function()
        Snacks.picker.git_log_file({
          on_show = function()
            vim.cmd.stopinsert()
          end,
        })
      end,
      desc = "Git log file",
    },
  },
}
