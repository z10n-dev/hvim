vim.g.mapleader = " "

local map = vim.keymap.set

vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, {
    desc = "Diagnostic: Show current",
})

vim.keymap.set("n", "<leader>dn", function()
    vim.diagnostic.jump({ count = 1 })
end, {
    desc = "Diagnostic: Next diagnostic",
})

vim.keymap.set("n", "<leader>dp", function()
    vim.diagnostic.jump({ count = -1 })
end, {
    desc = "Diagnostic: Previous diagnostic",
})
