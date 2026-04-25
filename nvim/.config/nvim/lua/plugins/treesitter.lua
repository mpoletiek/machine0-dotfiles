return {
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'master',
        lazy = false,
        build = ':TSUpdate',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        config = function()
            require('nvim-treesitter.configs').setup({
                highlight = { enable = true },
                indent = { enable = true },
                auto_install = false,
                ensure_installed = {
                    'bash',
                    'c',
                    'cpp',
                    'css',
                    'csv',
                    'diff',
                    'dockerfile',
                    'gitignore',
                    'go',
                    'graphql',
                    'html',
                    'java',
                    'javascript',
                    'jsdoc',
                    'json',
                    'json5',
                    'kotlin',
                    'lua',
                    'luadoc',
                    'markdown',
                    'markdown_inline',
                    'nginx',
                    'php',
                    'python',
                    'query',
                    'regex',
                    'rust',
                    'scss',
                    'solidity',
                    'sql',
                    'toml',
                    'tsx',
                    'typescript',
                    'vim',
                    'vimdoc',
                    'yaml',
                },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection    = '<CR>',    -- start selecting AST node
                        node_incremental  = '<CR>',    -- expand to parent
                        scope_incremental = '<S-CR>',
                        node_decremental  = '<BS>',    -- shrink back down
                    },
                },
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            -- `af`/`if` function, `ac`/`ic` class, `aa`/`ia` argument
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                            ['ac'] = '@class.outer',
                            ['ic'] = '@class.inner',
                            ['aa'] = '@parameter.outer',
                            ['ia'] = '@parameter.inner',
                            ['ab'] = '@block.outer',
                            ['ib'] = '@block.inner',
                            ['al'] = '@loop.outer',
                            ['il'] = '@loop.inner',
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            [']f'] = '@function.outer',
                            [']c'] = '@class.outer',
                            [']a'] = '@parameter.inner',
                        },
                        goto_previous_start = {
                            ['[f'] = '@function.outer',
                            ['[c'] = '@class.outer',
                            ['[a'] = '@parameter.inner',
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next     = { ['<leader>sa'] = '@parameter.inner' },
                        swap_previous = { ['<leader>sA'] = '@parameter.inner' },
                    },
                },
            })
        end,
    },
    {
        'windwp/nvim-ts-autotag',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            require('nvim-ts-autotag').setup({})
        end,
    },
}
