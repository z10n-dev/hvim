return {
    {
        "nvim-telescope/telescope.nvim",
        version = "*",
        dependencies = { "nvim-lua/plenary.nvim" },

        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")

            telescope.setup({})

            vim.keymap.set("n", "<leader>ff", builtin.find_files, {
    desc = "Find: Files",
})

vim.keymap.set("n", "<leader>fg", builtin.live_grep, {
    desc = "Find: Text",
})

vim.keymap.set("n", "<leader>fb", builtin.buffers, {
    desc = "Find: Buffers",
})

vim.keymap.set("n", "<leader>fh", builtin.help_tags, {
    desc = "Find: Help",
})

vim.keymap.set("n", "<leader>fr", builtin.oldfiles, {
    desc = "Find: Recent files",
})

vim.keymap.set("n", "<leader>?", builtin.keymaps, {
    desc = "Help: Show keymaps",
})     
        end,
    },
}
