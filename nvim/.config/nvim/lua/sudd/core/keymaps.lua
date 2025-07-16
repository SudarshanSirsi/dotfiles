local opts = { noremap = true, silent = true }

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "move down in buffer with cursor centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "move up in buffer with cursor centered" })
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- ctrl c as escape cuz Im lazy to reach up to the esc key
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("n", "<C-c>", ":nohl<CR>", { desc = "Clear search hl", silent = true })

-- format without prettier using the built in
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- Unmaps Q in normal mode
vim.keymap.set("n", "Q", "<nop>")

--Stars new tmux session from in here
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- prevent x delete from registering when next paste
vim.keymap.set("n", "x", '"_x', opts)

-- Replace the word under the cursor globally
vim.keymap.set("n", "<leader>sg", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = "Replace word cursor is on globally" })

-- Search and replace from the selected texts 
vim.keymap.set("v", "<leader>v", [[:s/\<\>//gI<Left><Left><Left><Left><Left><Left>]],
    { desc = "Search and replace from the selected texts" })

--Replace word cursor after confirming
vim.keymap.set("n", "<leader>sc", [[:%s/<C-r><C-w>/<C-r><C-w>/gcI<Left><Left><Left><Left>]],
    { desc = "Replace word cursor after confirming" })


-- Executes shell command from in here making file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "makes file executable" })


-- tab stuff
vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>")   --open new tab
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>") --close current tab
vim.keymap.set("n", "<leader>tn", "<cmd>tabn<CR>")     --go to next
vim.keymap.set("n", "<leader>tp", "<cmd>tabp<CR>")     --go to pre
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>") --open current tab in new tab

--split management
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
-- split window vertically
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
-- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
-- close current split window
vim.keymap.set("n", "<leader>xx", "<cmd>close<CR>", { desc = "Close current split" })

-- Copy filepath to the clipboard
vim.keymap.set("n", "<leader>fp", function()
    local filePath = vim.fn.expand("%:~")                -- Gets the file path relative to the home directory
    vim.fn.setreg("+", filePath)                         -- Copy the file path to the clipboard register
    print("File path copied to clipboard: " .. filePath) -- Optional: print message to confirm
end, { desc = "Copy file path to clipboard" })

-- Toggle LSP diagnostics visibility
local isLspDiagnosticsVisible = true
vim.keymap.set("n", "<leader>lx", function()
    isLspDiagnosticsVisible = not isLspDiagnosticsVisible
    vim.diagnostic.config({
        virtual_text = isLspDiagnosticsVisible,
        underline = isLspDiagnosticsVisible
    })
end, { desc = "Toggle LSP diagnostics" })

-- select all from a file
vim.keymap.set({ "n", "v" }, "<C-a>", "[[v]]$", { desc = "Select all" })


vim.keymap.set("n", "<leader>ll", ":vsplit ~/Documents/nettool/app.log<CR>")

-- To run terminla commands quickly (This opens the terminal from the location where nvim is opened first)
vim.keymap.set('n', '<leader>t', ':terminal ', { noremap = true, silent = false, desc = "Prefill :Ter command" })
-- Map <leader>t to prefill :Ter in the command line
vim.keymap.set('n', '<leader>T', ':Ter ', { noremap = true, silent = false, desc = "Prefill :Ter command" })

-- Define the :Ter user command
vim.api.nvim_create_user_command('Ter', function(args)
    local buf_dir = vim.fn.expand('%:p:h') -- Get current buffer's directory
    local cmd = args.args                -- Get the command passed to :Ter
    -- Open terminal and run 'cd <dir> && <command>'
    vim.cmd('terminal cd ' .. vim.fn.shellescape(buf_dir) .. ' && ' .. cmd)
end, { nargs = '*', desc = "Run terminal command in current buffer's directory" })
