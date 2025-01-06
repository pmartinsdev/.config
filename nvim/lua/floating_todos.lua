local floating_todos = {}

local floating_window_id = nil
local floating_buffer_id = nil
local close_on_next_esc = false

local function create_directory_if_not_exists(directory_path)
	if vim.fn.isdirectory(directory_path) == 0 then
		vim.fn.mkdir(directory_path, "p")
	end
end

local function get_project_name()
	local current_directory = vim.fn.getcwd()
	local directory_name = vim.fn.fnamemodify(current_directory, ":t")
	return directory_name
end

local function get_todo_file_path()
	local project_name = get_project_name()
	local todos_folder = vim.fn.expand("~/.todos") .. "/" .. project_name
	create_directory_if_not_exists(todos_folder)
	return todos_folder .. "/todo.md"
end

local function create_floating_window()
	local height = math.floor(vim.o.lines * 0.7)
	local width = math.floor(vim.o.columns * 0.7)
	local row_position = math.floor((vim.o.lines - height) / 2)
	local column_position = math.floor((vim.o.columns - width) / 2)
	local new_buffer = vim.api.nvim_create_buf(false, true)
	local window_options = {
		relative = "editor",
		width = width,
		height = height,
		row = row_position,
		col = column_position,
		style = "minimal",
		border = "rounded",
	}
	local new_window = vim.api.nvim_open_win(new_buffer, true, window_options)
	return new_window, new_buffer
end

function floating_todos.mark_close_on_next_esc()
	close_on_next_esc = true
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

function floating_todos.conditional_close_floating_todos()
	if close_on_next_esc and floating_window_id then
		floating_todos.close_floating_todos()
		close_on_next_esc = false
	else
		close_on_next_esc = false
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	end
end

function floating_todos.open_floating_todos()
	if floating_window_id then
		return
	end
	local todo_file_path = get_todo_file_path()
	local new_window, new_buffer = create_floating_window()
	floating_window_id = new_window
	floating_buffer_id = new_buffer
	vim.api.nvim_buf_call(new_buffer, function()
		vim.cmd("edit " .. todo_file_path)
	end)
	vim.api.nvim_buf_set_keymap(
		new_buffer,
		"i",
		"<Esc>",
		"<Cmd>lua require('floating_todos').mark_close_on_next_esc()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		new_buffer,
		"n",
		"<Esc>",
		"<Cmd>lua require('floating_todos').conditional_close_floating_todos()<CR>",
		{ noremap = true, silent = true }
	)
end

function floating_todos.close_floating_todos()
	if floating_buffer_id and vim.api.nvim_buf_is_valid(floating_buffer_id) then
		vim.api.nvim_buf_call(floating_buffer_id, function()
			vim.cmd("write")
		end)
	end
	if floating_window_id and vim.api.nvim_win_is_valid(floating_window_id) then
		vim.api.nvim_win_close(floating_window_id, true)
	end
	if floating_buffer_id and vim.api.nvim_buf_is_valid(floating_buffer_id) then
		vim.api.nvim_buf_delete(floating_buffer_id, { force = true })
	end
	floating_window_id = nil
	floating_buffer_id = nil
	close_on_next_esc = false
end

function floating_todos.setup()
	vim.api.nvim_create_user_command("OpenTodos", function()
		floating_todos.open_floating_todos()
	end, {})
	vim.api.nvim_create_user_command("CloseTodos", function()
		floating_todos.close_floating_todos()
	end, {})
end

return floating_todos
