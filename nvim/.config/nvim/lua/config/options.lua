-- ============================================================================
-- Display
-- ============================================================================
vim.opt.termguicolors   = true                    -- 24-bit color (required by modern themes/treesitter)
vim.opt.number          = true
vim.opt.relativenumber  = true                    -- relative line numbers for vim motions
vim.opt.cursorline      = true
vim.opt.signcolumn      = 'yes'                   -- always render sign column so buffer doesn't shift
vim.opt.scrolloff       = 8
vim.opt.sidescrolloff   = 8
vim.opt.wrap            = false
vim.opt.showmode        = false                   -- mode shown in lualine already

-- ============================================================================
-- Indentation (match existing shiftwidth=4)
-- ============================================================================
vim.opt.expandtab       = true                    -- spaces, not tabs
vim.opt.shiftwidth      = 4
vim.opt.tabstop         = 4
vim.opt.softtabstop     = 4
vim.opt.smartindent     = true
vim.opt.autoindent      = true

-- ============================================================================
-- Search
-- ============================================================================
vim.opt.ignorecase      = true
vim.opt.smartcase       = true                    -- case-sensitive when pattern has uppercase
vim.opt.hlsearch        = true
vim.opt.incsearch       = true

-- ============================================================================
-- Files / persistence
-- ============================================================================
vim.opt.swapfile        = false
vim.opt.backup          = false
vim.opt.undofile        = true                    -- persistent undo across sessions
vim.opt.undodir         = vim.fn.stdpath('data') .. '/undo'

-- ============================================================================
-- Splits
-- ============================================================================
vim.opt.splitright      = true
vim.opt.splitbelow      = true

-- ============================================================================
-- UX
-- ============================================================================
vim.opt.updatetime      = 250                     -- faster autoread checks / CursorHold
vim.opt.timeoutlen      = 500                     -- shorter which-key popup delay
vim.opt.mouse           = 'a'
vim.opt.clipboard       = 'unnamedplus'           -- yank -> CLIPBOARD (Ctrl+Shift+V); middle-click pastes PRIMARY separately
vim.opt.completeopt     = 'menuone,noselect,noinsert'

-- ============================================================================
-- Auto-reload buffers when underlying file changes
-- ============================================================================
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
    callback = function()
        if vim.fn.mode() ~= 'c' then
            vim.cmd('checktime')
        end
    end,
})

-- ============================================================================
-- Highlight yank briefly (visual feedback on <y>)
-- ============================================================================
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank({ timeout = 150 })
    end,
})
