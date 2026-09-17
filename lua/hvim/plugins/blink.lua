return {
    {
        "saghen/blink.cmp",
        version = "1.*",

        opts = {
            keymap = {
                preset = "default",

                ["<CR>"] = { "accept", "fallback" },
            },

            completion = {
                documentation = {
                    auto_show = false,
                },
            },

            sources = {
                default = {
                    "lsp",
                    "path",
                    "snippets",
                    "buffer",
                },
            },
        },
    },
}
