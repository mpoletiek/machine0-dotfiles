return {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePost' },
    config = function()
        local lint = require('lint')

        lint.linters_by_ft = {
            python = { 'ruff' },
            javascript = { 'eslint_d' },
            typescript = { 'eslint_d' },
            javascriptreact = { 'eslint_d' },
            typescriptreact = { 'eslint_d' },
            sh = { 'shellcheck' },
            bash = { 'shellcheck' },
        }

        local group = vim.api.nvim_create_augroup('user-nvim-lint', { clear = true })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
            group = group,
            callback = function()
                lint.try_lint()
            end,
        })

        vim.keymap.set('n', '<leader>l', function()
            lint.try_lint()
        end, { desc = 'Trigger linter' })
    end,
}
