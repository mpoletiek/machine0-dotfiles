return {
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'saghen/blink.cmp',
        },
        config = function()
            local capabilities = require('blink.cmp').get_lsp_capabilities()

            local servers = {
                pyright = {},
                vtsls = {},
                solidity_ls = {},
                jsonls = {},
                yamlls = {},
                html = {},
                cssls = {},
                bashls = {},
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = { checkThirdParty = false },
                            telemetry = { enable = false },
                            diagnostics = { globals = { 'vim' } },
                            hint = { enable = true },   -- enables inlay hints for lua_ls
                        },
                    },
                },
            }

            for name, opts in pairs(servers) do
                opts.capabilities = vim.tbl_deep_extend(
                    'force',
                    {},
                    capabilities,
                    opts.capabilities or {}
                )
                vim.lsp.config(name, opts)
                vim.lsp.enable(name)
            end

            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
                callback = function(event)
                    local map = function(lhs, rhs, desc)
                        vim.keymap.set('n', lhs, rhs, { buffer = event.buf, desc = 'LSP: ' .. desc })
                    end

                    map('gd',         vim.lsp.buf.definition,       'Go to definition')
                    map('gD',         vim.lsp.buf.declaration,      'Go to declaration')
                    map('gi',         vim.lsp.buf.implementation,   'Go to implementation')
                    map('gy',         vim.lsp.buf.type_definition,  'Go to type definition')
                    map('gr',         vim.lsp.buf.references,       'References')
                    map('K',          vim.lsp.buf.hover,            'Hover docs')
                    map('<leader>rn', vim.lsp.buf.rename,           'Rename symbol')
                    map('<leader>ca', vim.lsp.buf.code_action,      'Code action')
                    map('<leader>d',  vim.diagnostic.open_float,    'Line diagnostics')
                    map('[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Prev diagnostic')
                    map(']d', function() vim.diagnostic.jump({ count =  1, float = true }) end, 'Next diagnostic')

                    -- Inlay hints (if server supports them) + toggle
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
                        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
                        map('<leader>ih', function()
                            vim.lsp.inlay_hint.enable(
                                not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }),
                                { bufnr = event.buf }
                            )
                        end, 'Toggle inlay hints')
                    end
                end,
            })

            vim.diagnostic.config({
                virtual_text  = true,
                severity_sort = true,
                float         = { border = 'rounded', source = 'if_many' },
            })
        end,
    },

    {
        'saghen/blink.cmp',
        version = '*',
        dependencies = {
            -- Community snippet library. blink.cmp auto-discovers these via its
            -- default snippets source (friendly-snippets ships LSP-style JSON).
            'rafamadriz/friendly-snippets',
        },
        opts = {
            keymap = { preset = 'default' },
            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant       = 'mono',
            },
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },
        },
        opts_extend = { 'sources.default' },
    },
}
