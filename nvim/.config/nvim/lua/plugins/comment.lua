return {
    {
        'numToStr/Comment.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = {
            -- Context-aware commentstring for embedded langs (JSX, Vue, etc.)
            'JoosepAlviste/nvim-ts-context-commentstring',
        },
        config = function()
            require('ts_context_commentstring').setup({ enable_autocmd = false })
            require('Comment').setup({
                pre_hook = require('ts_context_commentstring.integrations.comment_nvim')
                    .create_pre_hook(),
            })
            -- Default binds provided by Comment.nvim:
            --   gcc        toggle line comment
            --   gc{motion} toggle comment over motion (gcap = paragraph)
            --   gbc        toggle block comment
            --   gb{motion} toggle block comment over motion
            -- In visual mode, `gc` / `gb` apply to selection.
        end,
    },
}
