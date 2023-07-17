return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  config = function ()
    require('nvim-treesitter.configs').setup {
      ensure_installed = {
        'lua',
        'vim',
        'vimdoc',
        'python',
        'dockerfile',
        'yaml',
        'terraform',
        'go',
        'git_rebase',
        'gitcommit',
        'gitignore',
      },

      auto_install = true,

      highlight = {
        enable = true,
      }
    }
  end
}

