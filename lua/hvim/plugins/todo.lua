return {
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },

        opts = {},

        config = function(_, opts)
            require("todo-comments").setup(opts)

            vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find TODOs" })
        end,
    },
}
