return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "pyright",
                    "vtsls",
                    "solidity_ls",
                    "lua_ls",
                    "jsonls",
                    "yamlls",
                    "html",
                    "cssls",
                    "bashls",
                },
                automatic_enable = false,
            })
        end,
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        config = function()
            require("mason-tool-installer").setup({
                ensure_installed = {
                    "prettier",
                    "ruff",
                    "eslint_d",
                    "shellcheck",
                    "stylua",
                },
            })
        end,
    },
}
