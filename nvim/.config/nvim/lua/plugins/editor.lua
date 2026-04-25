return {
    {
        'windwp/nvim-autopairs',
        event = 'InsertEnter',
        opts = {
            check_ts = true,
            fast_wrap = {},
        },
    },
    {
        'lukas-reineke/indent-blankline.nvim',
        main = 'ibl',
        event = { 'BufReadPost', 'BufNewFile' },
        opts = {
            indent = { char = '│' },
            scope = { enabled = true, show_start = false, show_end = false },
        },
    },
    {
        'akinsho/toggleterm.nvim',
        version = '*',
        keys = {
            { '<C-\\>', '<cmd>ToggleTerm<cr>', desc = 'Toggle terminal', mode = { 'n', 't' } },
            { '<leader>tf', '<cmd>ToggleTerm direction=float<cr>', desc = 'Floating terminal' },
            { '<leader>th', '<cmd>ToggleTerm direction=horizontal<cr>', desc = 'Horizontal terminal' },
            { '<leader>tv', '<cmd>ToggleTerm direction=vertical size=80<cr>', desc = 'Vertical terminal' },
        },
        opts = {
            open_mapping = [[<C-\>]],
            direction = 'float',
            float_opts = { border = 'curved' },
            shade_terminals = true,
        },
    },
}
