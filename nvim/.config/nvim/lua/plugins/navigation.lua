return {
    {
        'stevearc/aerial.nvim',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'nvim-tree/nvim-web-devicons',
        },
        keys = {
            { '<leader>o', '<cmd>AerialToggle!<cr>', desc = 'Toggle symbol outline' },
            { '<leader>O', '<cmd>AerialNavToggle<cr>', desc = 'Toggle floating outline' },
        },
        opts = {
            backends = { 'lsp', 'treesitter', 'markdown', 'man' },
            layout = {
                min_width = 30,
                default_direction = 'right',
            },
            show_guides = true,
            filter_kind = false,
            on_attach = function(bufnr)
                vim.keymap.set('n', '{', '<cmd>AerialPrev<cr>', { buffer = bufnr, desc = 'Prev symbol' })
                vim.keymap.set('n', '}', '<cmd>AerialNext<cr>', { buffer = bufnr, desc = 'Next symbol' })
            end,
        },
    },
    {
        'nvim-pack/nvim-spectre',
        dependencies = { 'nvim-lua/plenary.nvim' },
        keys = {
            { '<leader>sr', function() require('spectre').toggle() end, desc = 'Spectre: search/replace' },
            { '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end, desc = 'Spectre: current word' },
            { '<leader>sw', function() require('spectre').open_visual() end, mode = 'v', desc = 'Spectre: selection' },
            { '<leader>sp', function() require('spectre').open_file_search({ select_word = true }) end, desc = 'Spectre: in current file' },
        },
        opts = {},
    },
}
