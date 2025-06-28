-- Terminal Float State (taught by tj)
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")

local current_index = 0
local terminals = {}

-- namespace id for terminal names
local ns = vim.api.nvim_create_namespace("TerminalListNS")
vim.api.nvim_set_hl(
    0,
    "TerminalTitle",
    {
        fg = "#000000",
        bg = "#00ffff",
        bold = true
    }
)

local function hide_all_terminal_windows()
    for _, term in ipairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            vim.api.nvim_win_hide(term.win)
        end
    end
end

-- Function to apply winbar for terminal buffer
local function set_terminal_winbar(win, selected_index)

    local term =terminals[selected_index] or  terminals[current_index]
    if not term or not term.name then return end

    local winbar_content = "%=%#TerminalTitle#" .. "<" .. term.name .. ">" .. "%#Normal#%="
    vim.api.nvim_set_option_value("winbar", winbar_content, { win = win })
end

local function rename_current_terminal()
    local term = terminals[current_index]
    if not term then return end

    -- Prompt for new name
    vim.ui.input({ prompt = "Rename terminal to: " }, function(input)
        if input and input ~= "" then
            term.name = input
            -- Update winbar
            local winbar = "%=%#TerminalTitle#" .. input .. "%#Normal#%="
            if term.win and vim.api.nvim_win_is_valid(term.win) then
                vim.api.nvim_set_option_value("winbar", winbar, { win = term.win })
            end
        end
    end)
end

local function create_floating_window(opts)
    opts = opts or {}
    local width = opts.width or math.floor(vim.o.columns * 0.8)
    local height = opts.height or math.floor(vim.o.lines * 0.9)

    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    local buf = nil
    if opts.buf and type(opts.buf) == "number" and vim.api.nvim_buf_is_valid(opts.buf) then
        buf = opts.buf
    else
        buf = vim.api.nvim_create_buf(false, true)
    end

    local win_config = {
        relative = "editor",
        border = "rounded",
        style = "minimal",
        width = width,
        height = height,
        col = col,
        row = row,
    }

    local win = vim.api.nvim_open_win(buf, true, win_config)

    return { buf = buf, win = win }
end

-- switch between the terminals
local function switch_terminal(offset)
    if #terminals == 0 then return end

    -- Compute the next index with wraparound
    current_index = ((current_index + offset - 1) % #terminals) + 1

    local term = terminals[current_index]

    -- Hide all existing terminal windows
    hide_all_terminal_windows()

    -- Reopen the selected terminal
    if vim.api.nvim_buf_is_valid(term.buf) then
        local new_term = create_floating_window({ buf = term.buf })
        vim.api.nvim_set_current_win(new_term.win)
        vim.cmd("startinsert!")
        term.win = new_term.win
        set_terminal_winbar(new_term.win)
    end
end

-- To create new terminal buf
local function create_new_terminal()
    -- create new buff+ terminal
    local index = #terminals + 1
    local term = create_floating_window()
    local name = "Terminal " .. index
    term.name = name

    -- switch to it and open a new terminal job
    vim.api.nvim_set_current_win(term.win)
    vim.cmd("terminal")
    vim.cmd("startinsert!")
    table.insert(terminals, term)
    current_index = index
    set_terminal_winbar(term.win)
end

-- to toggle the last opened terminal
local function toggle_last_terminal()
    local term = terminals[#terminals]
    if not term then
        create_new_terminal()
        return
    end

    if vim.api.nvim_win_is_valid(term.win) then
        hide_all_terminal_windows()
    else
        -- Recreate window using same buffer
        local new_term = create_floating_window({ buf = term.buf })
        vim.api.nvim_set_current_win(new_term.win)
        vim.cmd("startinsert!")
        -- Update the window ID
        term.win = new_term.win
    end
end

local function remove_current_terminal_buff()
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_win_get_buf(current_win)

    for i, term in ipairs(terminals) do
        if term.buf == current_buf then
            -- Delete the window if it's valid
            if vim.api.nvim_win_is_valid(term.win) then
                vim.api.nvim_win_close(term.win, true)
            end

            -- Delete the buffer
            if vim.api.nvim_buf_is_valid(term.buf) then
                vim.api.nvim_buf_delete(term.buf, { force = true })
            end

            -- Remove from terminals list
            table.remove(terminals, i)

            -- Adjust current index
            if current_index > #terminals then
                current_index = #terminals
            end

            vim.notify("Terminal deleted.")
            return
        end
    end
end

local function show_terminal_list()
    if #terminals == 0 then
        vim.notify("No terminals open.")
        return
    end

    -- Create temporary buffer
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = {}
    for i, terminal in ipairs(terminals) do
        table.insert(lines, string.format("[%d]  %s", i, terminal.name))
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

    local width = 30
    local height = #lines
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    -- Current selection
    local selected = 1

    local function highlight_and_switch()
        vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
        vim.highlight.range(
            buf,
            ns,
            "Visual",
            { selected - 1, 0 },
            { selected - 1, -1 },
            { inclusive = true }
        )

        -- Switch terminal in background
        local term = terminals[selected]
        if term and vim.api.nvim_buf_is_valid(term.buf) then
            hide_all_terminal_windows()
            local new_term = create_floating_window({ buf = term.buf })
            term.win = new_term.win
            vim.api.nvim_set_current_win(term.win)
            set_terminal_winbar(new_term.win, selected)

            -- Go back to terminal list window
            vim.api.nvim_set_current_win(win)
        end
    end

    highlight_and_switch()

    local function remove_terminal_from_list()
        local term = terminals[selected]
        if not term then return end

        -- Close the terminal window if it's open
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            vim.api.nvim_win_close(term.win, true)
        end

        -- Delete the buffer if valid
        if vim.api.nvim_buf_is_valid(term.buf) then
            vim.api.nvim_buf_delete(term.buf, { force = true })
        end

        -- Remove from terminals list
        table.remove(terminals, selected)

        -- Adjust selection
        if selected > #terminals then
            selected = #terminals
        end
        if selected < 1 then
            vim.api.nvim_win_close(win, true)
            return
        end

        -- Update buffer lines
        lines = {}
        for i, _ in ipairs(terminals) do
            table.insert(lines, string.format("[%d]  %s", i, term.name))
        end
        vim.api.nvim_set_option_value( "modifiable", true, {buf = buf})
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_set_option_value( "modifiable", false, {buf = buf})

        -- Update window height
        vim.api.nvim_win_set_height(win, #lines)

        -- Re-highlight and update terminal preview
        highlight_and_switch()

    end

    local function rename_terminal_from_list()
        local term = terminals[selected]
        if not term then return end


        -- Prompt for new name
        vim.ui.input({ prompt = "Rename terminal to: " }, function(input)
            if input and input ~= "" then
                term.name = input
                -- Update winbar
                local winbar = "%=%#TerminalTitle#" .. input .. "%#Normal#%="
                if term.win and vim.api.nvim_win_is_valid(term.win) then
                    vim.api.nvim_set_option_value("winbar", winbar, { win = term.win })
                end
            end
        end)

        -- Update buffer lines
        lines = {}
        for i, _ in ipairs(terminals) do
            table.insert(lines, string.format("[%d]  %s", i, term.name))
        end
        vim.api.nvim_set_option_value( "modifiable", true, {buf = buf})
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_set_option_value( "modifiable", false, {buf = buf})

        -- Re-highlight and update terminal preview
        highlight_and_switch()

    end

    -- Keymaps
    vim.keymap.set("n", "j", function()
        if selected < #terminals then
            selected = selected + 1
            highlight_and_switch()
        end
    end, { buffer = buf })

    vim.keymap.set("n", "k", function()
        if selected > 1 then
            selected = selected - 1
            highlight_and_switch()
        end
    end, { buffer = buf })

    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.keymap.set("n", "<Esc>", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.keymap.set("n", "<M-a>", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.keymap.set("n", "<CR>", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })


    vim.keymap.set("n", "<M-i>", function()
        vim.api.nvim_win_close(win, true)
        hide_all_terminal_windows()
    end, { buffer = buf })

    vim.keymap.set("n", "ddd", function ()
        remove_terminal_from_list()
    end, { buffer = buf } )

    vim.keymap.set("n", "rr", function ()
        rename_terminal_from_list()
    end, { buffer = buf } )
end

-- keymaps
vim.api.nvim_create_user_command("NewTerm", create_new_terminal, {})
vim.api.nvim_create_user_command("ToggleLastTerm", toggle_last_terminal, {})

vim.keymap.set({ "n", "t" }, "<M-i>", toggle_last_terminal)
vim.keymap.set({ "n", "t" }, "<M-t>", create_new_terminal)

vim.keymap.set({ "n", "t" }, "<M-n>", function() switch_terminal(1) end)
vim.keymap.set({ "n", "t" }, "<M-p>", function() switch_terminal(-1) end)

vim.keymap.set({ "n", "t" }, "<M-r>", rename_current_terminal)
vim.keymap.set({ "n", "t" }, "<M-d>", remove_current_terminal_buff)
vim.keymap.set({ "n", "t" }, "<M-a>", show_terminal_list)
