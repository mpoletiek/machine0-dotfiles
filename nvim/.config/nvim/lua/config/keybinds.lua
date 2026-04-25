vim.g.mapleader = ' '

local map = vim.keymap.set

-- File tree / netrw fallback
map('n', '<leader>cd', vim.cmd.Ex, { desc = 'Open netrw' })

-- ============================================================================
-- Buffer navigation (bufferline)
-- ============================================================================
map('n', '<Tab>',   '<cmd>BufferLineCycleNext<cr>', { desc = 'Next Buffer' })
map('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Previous Buffer' })

-- ============================================================================
-- Terminal keycode compat (xterm vs rxvt)
-- ============================================================================
for _, mode in ipairs({ 'n', 'i', 'v', 'c', 'o', 's', 'x' }) do
    map(mode, '<Find>',   '<Home>', { silent = true })
    map(mode, '<Select>', '<End>',  { silent = true })
end

-- ============================================================================
-- Editor QoL
-- ============================================================================

-- Stay in visual mode after indent
map('v', '<', '<gv', { desc = 'Indent left, keep selection' })
map('v', '>', '>gv', { desc = 'Indent right, keep selection' })

-- Move visual block up/down, auto-reindent
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Center cursor after big jumps / search matches
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n',     'nzzzv')
map('n', 'N',     'Nzzzv')

-- Keep cursor still on J (line join)
map('n', 'J', 'mzJ`z')

-- Paste over selection without overwriting register
map('x', '<leader>p', '"_dP', { desc = 'Paste without yank' })

-- Yank to system clipboard explicitly (reinforces default behavior)
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to system clipboard' })

-- Delete without yanking (black-hole register)
map({ 'n', 'v' }, '<leader>D', '"_d', { desc = 'Delete (no yank)' })

-- Clear search highlight
map('n', '<leader>nh', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- Quick save / quit
map('n', '<leader>w',  '<cmd>write<CR>',   { desc = 'Write buffer' })
map('n', '<leader>q',  '<cmd>confirm q<CR>', { desc = 'Quit (confirm)' })
map('n', '<leader>Q',  '<cmd>qa!<CR>',     { desc = 'Force quit all' })

-- Quick window navigation
map('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-l>', '<C-w>l', { desc = 'Window right' })

-- Resize splits with Ctrl+Arrow
map('n', '<C-Up>',    '<cmd>resize +2<CR>')
map('n', '<C-Down>',  '<cmd>resize -2<CR>')
map('n', '<C-Left>',  '<cmd>vertical resize -2<CR>')
map('n', '<C-Right>', '<cmd>vertical resize +2<CR>')

-- ============================================================================
-- Custom commands
-- ============================================================================
vim.api.nvim_create_user_command('Tutorial', function()
    vim.cmd('edit ' .. vim.fn.stdpath('config') .. '/tutorial.md')
end, {})
