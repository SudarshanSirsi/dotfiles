local api = vim.api
local fn = vim.fn

-- Hightlight yanking
api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Define project-specific keymap for myapp
-- api.nvim_create_autocmd("BufEnter", {
--     pattern = "~/Documents/nettool/*", -- Adjust to your project path
--     callback = function()
--         local filePath = "~/Documents/nettool/app.log"
--         -- Keymap to open myapp.log in a vertical split
--         api.nvim_buf_set_keymap(0, "n", "<leader>ll", ":vsplit " .. fn.expand(filePath) .. "<CR>", {
--             noremap = true,
--             silent = true,
--             desc = "Open app.log in vertical split",
--         })
--     end,
-- })
