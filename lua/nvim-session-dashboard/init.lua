-- lua/hello-world/init.lua
local M = {}
M.config = {
	sessions_dir = vim.fn.expand("~/.vim-sessions"), -- Default sessions directory
}

-- Function to configure the plugin
function M.setup(options)
	M.config = vim.tbl_extend("force", M.config, options or {})
end

local sort_order = "mtime" -- Change to "alpha" for alphabetical order

-- Function to list sessions based on the chosen order
local function list_sessions()
	local sessions = vim.fn.globpath(M.config.sessions_dir, "*")

	if #sessions == 0 then
		return {}
	end

	local session_list = vim.split(sessions, "\n")

	if sort_order == "mtime" then
		-- Sort by file modification time (descending order)
		table.sort(session_list, function(a, b)
			return vim.fn.getftime(a) > vim.fn.getftime(b)
		end)
	elseif sort_order == "alpha" then
		-- Sort alphabetically
		table.sort(session_list)
	end

	return session_list
end

-- Function to generate index label
local function get_index_label(index)
	if index <= 9 then
		return tostring(index) -- Numbers 1-9
	elseif index == 10 then
		return "0" -- Number 10 is "0"
	else
		return string.char(86 + index) -- 11 -> 'a', 12 -> 'b', etc., using ASCII
	end
end

-- Function to show session buffer
function M.show_session_buffer()
	local sessions = list_sessions()
	local buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)

	local lines = { "Available sessions (Sorted by " .. sort_order .. "):" }
	for i, session in ipairs(sessions) do
		local index_label = get_index_label(i)
		table.insert(lines, " " .. index_label .. ": " .. vim.fn.fnamemodify(session, ":t"))
	end
	table.insert(lines, "")
	table.insert(lines, " [n] New session")
	table.insert(lines, " [r] Reload this view")
	table.insert(lines, " [q] Quit")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines) -- Set lines in buffer
	vim.api.nvim_set_current_buf(buf)

	-- Create key mappings for interacting with the session buffer
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"n",
		[[:lua require('nvim-session-dashboard').create_new_session()<CR>]],
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"r",
		[[:lua require('nvim-session-dashboard').show_session_buffer()<CR>]],
		{ noremap = true, silent = true }
	) -- Reload key mapping

	for i = 1, #sessions do
		local index_label = get_index_label(i)
		vim.api.nvim_buf_set_keymap(
			buf,
			"n",
			index_label,
			[[:lua require('nvim-session-dashboard').load_session(]] .. i .. [[)<CR>]],
			{ noremap = true, silent = true }
		)
	end
end

-- Function to load a selected session
function M.load_session(index)
	local sessions = list_sessions()
	if sessions[index] then
		local session_path = sessions[index] -- This already contains the full path

		vim.cmd("%bd") -- Close all open buffers
		vim.cmd("silent! only") -- Close all windows except the current one

		vim.cmd("source " .. session_path)
	else
		print("Invalid session index")
	end
end

-- Function to create a new session
function M.create_new_session()
	local session_name = vim.fn.input("New session name: ")
	if session_name ~= "" then
		local session_path = M.config.sessions_dir .. "/" .. session_name
		vim.cmd("Obsession " .. session_path)
		print("Created new session: " .. session_name)
		vim.cmd("bd") -- Close the session buffer
	else
		print("Session name cannot be empty")
	end
end

-- Open session buffer on VimEnter if no files are opened
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then -- Only if no files are opened
			M.show_session_buffer()
		end
	end,
})

return M
