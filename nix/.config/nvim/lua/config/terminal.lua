local float_term_win = nil
local float_term_buf = nil

local function open_floating_terminal()
    -- Configuration for the floating window dimensions and position
    local width = vim.api.nvim_get_option("columns") * 0.9
    local height = vim.api.nvim_get_option("lines") * 0.9
    local col = (vim.api.nvim_get_option("columns") - width) / 2
    local row = (vim.api.nvim_get_option("lines") - height) / 2

    local opts = {
        relative = "editor",
        width = math.floor(width),
        height = math.floor(height),
        col = math.floor(col),
        row = math.floor(row),
        border = "rounded", -- Optional: use 'single', 'double', 'rounded', or 'none'
        style = "minimal", -- Hides features like 'number' column
    }

    -- Create a new buffer if one doesn't exist or if the old one is invalid
    if not float_term_buf or not vim.api.nvim_buf_is_valid(float_term_buf) then
        -- Create an unlisted scratch buffer (false for listed, true for scratch)
        float_term_buf = vim.api.nvim_create_buf(false, true)
    end

    -- Check if the window is already open and valid
    if float_term_win and vim.api.nvim_win_is_valid(float_term_win) then
        -- If open, just focus it
        vim.api.nvim_set_current_win(float_term_win)
    else
        -- Open the floating window with the buffer
        float_term_win = vim.api.nvim_open_win(float_term_buf, true, opts)
        -- Set the buffer to be a terminal buffer
        vim.cmd("terminal")
        -- Optional: set custom highlight for the border
        vim.api.nvim_win_set_option(float_term_win, 'winhighlight', 'NormalFloat:NormalFloat,FloatBorder:FloatBorder')
    end
end

-- Function to close the floating terminal
local function close_floating_terminal()
    if float_term_win and vim.api.nvim_win_is_valid(float_term_win) then
        vim.api.nvim_win_close(float_term_win, true)
        float_term_win = nil
    end
end

-- Function to toggle the floating terminal
local function toggle_floating_terminal()
    if float_term_win and vim.api.nvim_win_is_valid(float_term_win) then
        close_floating_terminal()
    else
        open_floating_terminal()
    end
end

-- Expose the toggle function to Neovim
vim.api.nvim_create_user_command("ToggleFloatTerm", toggle_floating_terminal, {})

-- Map a key (e.g., <leader>ft) to toggle the terminal
vim.api.nvim_set_keymap("n", "<leader>t", ":ToggleFloatTerm<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<leader>t", "<C-\\><C-n>:ToggleFloatTerm<CR>", { noremap = true, silent = true })

