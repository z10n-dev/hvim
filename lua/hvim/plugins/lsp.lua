return {
    {
        "mason-org/mason-lspconfig.nvim",
        opts = {
            ensure_installed = {
                "jdtls",
                "lua_ls",
                "jsonls",
                "yamlls",
                "bashls",
                "clangd",
                "basedpyright",
            },
        },

        dependencies = {
            {
                "mason-org/mason.nvim",
                opts = {},
            },

            "neovim/nvim-lspconfig",
        },
    },
}
