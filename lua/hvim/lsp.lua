local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("*", {
    capabilities = capabilities,
})

vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        local opts = { buffer = event.buf, silent = true }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
    buffer = event.buf,
    silent = true,
    desc = "LSP: Go to definition",
})

vim.keymap.set("n", "gr", vim.lsp.buf.references, {
    buffer = event.buf,
    silent = true,
    desc = "LSP: References",
})

vim.keymap.set("n", "K", vim.lsp.buf.hover, {
    buffer = event.buf,
    silent = true,
    desc = "LSP: Hover",
})

vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {
    buffer = event.buf,
    silent = true,
    desc = "LSP: Code action",
})

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {
    buffer = event.buf,
    silent = true,
    desc = "LSP: Rename",
})
        end,
})
