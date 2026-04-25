-- Everforest (dark, medium) — matches kitty/tmux/hyprland/noctalia
local function enable_transparency()
    vim.api.nvim_set_hl(0, 'Normal',            { bg = 'none' })
    vim.api.nvim_set_hl(0, 'NormalNC',          { bg = 'none' })
    vim.api.nvim_set_hl(0, 'NormalFloat',       { bg = 'none' })
    vim.api.nvim_set_hl(0, 'SignColumn',        { bg = 'none' })
    vim.api.nvim_set_hl(0, 'StatusLine',        { bg = 'none' })
    vim.api.nvim_set_hl(0, 'StatusLineNC',      { bg = 'none' })
    vim.api.nvim_set_hl(0, 'TelescopeNormal',   { bg = 'none' })
end

return {
    {
        'neanias/everforest-nvim',
        lazy = false,
        priority = 1000,
        config = function()
            require('everforest').setup({
                background = 'medium',           -- 'hard' | 'medium' | 'soft'
                transparent_background_level = 2,
                italics = true,
                disable_italic_comments = false,
                ui_contrast = 'high',
                show_eob = false,
                float_style = 'dim',
            })
            vim.o.background = 'dark'
            vim.cmd.colorscheme('everforest')
            enable_transparency()
        end,
    },

    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {
            options = {
                theme                 = 'everforest',
                section_separators    = { left = '', right = '' },
                component_separators  = { left = '│', right = '│' },
                globalstatus          = true,
            },
        },
    },
}
