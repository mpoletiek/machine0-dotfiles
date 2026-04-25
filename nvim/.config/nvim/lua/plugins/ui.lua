return {
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
        },
    },
    {
        "mrjones2014/legendary.nvim",
        priority = 10000,
        lazy = false,
        opts = {
            extensions = {
                which_key = { auto_register = true },
            },
        },
        keys = {
            { "<leader>p", "<cmd>Legendary<cr>", desc = "Command Palette" },
        },
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {},
    },
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            require("bufferline").setup({})
        end
    },
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup()
        end
    }
}
