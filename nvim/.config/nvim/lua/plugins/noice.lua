return {
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        dependencies = {
            'MunifTanjim/nui.nvim',
            'rcarriga/nvim-notify',
        },
        opts = {
            lsp = {
                override = {
                    ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                    ['vim.lsp.util.stylize_markdown']                = true,
                    ['cmp.entry.get_documentation']                  = true,
                },
            },
            presets = {
                bottom_search         = true,   -- classic bottom cmdline for search
                command_palette       = true,   -- position cmdline + popupmenu together
                long_message_to_split = true,   -- long messages go to a split
                inc_rename            = false,
                lsp_doc_border        = true,   -- bordered hover/signature docs
            },
            routes = {
                -- Skip repetitive "file written" messages
                {
                    filter = {
                        event = 'msg_show',
                        kind  = '',
                        find  = 'written',
                    },
                    opts = { skip = true },
                },
            },
        },
    },
    {
        'rcarriga/nvim-notify',
        opts = {
            render       = 'minimal',
            stages       = 'fade',
            timeout      = 3000,
            top_down     = false,  -- notifications rise from bottom-right
            background_colour = '#131313',
        },
    },
}
