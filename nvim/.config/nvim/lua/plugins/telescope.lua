return {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
        local telescope = require('telescope')
        local builtin = require('telescope.builtin')

        telescope.setup({
            defaults = {
                path_display = { 'smart' },
                mappings = {
                    i = {
                        ['<C-u>'] = false,                           -- free C-u for half-page scroll
                        ['<C-d>'] = require('telescope.actions').delete_buffer,
                    },
                },
            },
            pickers = {
                find_files = { hidden = true },
                live_grep  = { additional_args = function() return { '--hidden' } end },
            },
        })

        pcall(telescope.load_extension, 'fzf')

        -- File/buffer navigation
        vim.keymap.set('n', '<leader>ff', builtin.find_files,      { desc = 'Find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep,       { desc = 'Live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers,         { desc = 'Buffers' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags,       { desc = 'Help tags' })
        vim.keymap.set('n', '<leader>fo', builtin.oldfiles,        { desc = 'Recent files' })
        vim.keymap.set('n', '<leader>fr', builtin.resume,          { desc = 'Resume last picker' })
        vim.keymap.set('n', '<leader>fm', builtin.marks,           { desc = 'Marks' })

        -- Command / keymap discovery
        vim.keymap.set('n', '<leader>fk', builtin.keymaps,         { desc = 'Keymaps' })
        vim.keymap.set('n', '<leader>fc', builtin.commands,        { desc = 'Commands' })
        vim.keymap.set('n', '<leader>fd', builtin.diagnostics,     { desc = 'Diagnostics' })
        vim.keymap.set('n', '<leader>fs', builtin.current_buffer_fuzzy_find, { desc = 'Search in buffer' })

        -- Git
        vim.keymap.set('n', '<leader>gs', builtin.git_status,      { desc = 'Git status' })
        vim.keymap.set('n', '<leader>gc', builtin.git_commits,     { desc = 'Git commits' })
        vim.keymap.set('n', '<leader>gb', builtin.git_branches,    { desc = 'Git branches' })
    end,
}
