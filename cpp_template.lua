local buffer_number = -1

local cwd = vim.uv.cwd()

local function log(_, data)
	if data then
		-- Make it temporarily writable so we don't have warnings.
		vim.api.nvim_buf_set_option(buffer_number, "readonly", false)

		-- Append the data.
		vim.api.nvim_buf_set_lines(buffer_number, -1, -1, true, data)

		-- Make readonly again.
		vim.api.nvim_buf_set_option(buffer_number, "readonly", true)

		-- Mark as not modified, otherwise you'll get an error when
		-- attempting to exit vim.
		vim.api.nvim_buf_set_option(buffer_number, "modified", false)

		-- Get the window the buffer is in and set the cursor position to the bottom.
		local buffer_window = vim.api.nvim_call_function("bufwinid", { buffer_number })
		local buffer_line_count = vim.api.nvim_buf_line_count(buffer_number)
		vim.api.nvim_win_set_cursor(buffer_window, { buffer_line_count, 0 })
	end
end

local function open_buffer()
	-- Get a boolean that tells us if the buffer number is visible anymore.
	--
	-- :help bufwinnr
	local buffer_visible = vim.api.nvim_call_function("bufwinnr", { buffer_number }) ~= -1

	if buffer_number == -1 or not buffer_visible then
		-- Create a new buffer with the name "AUTOTEST_OUTPUT".
		-- Same name will reuse the current buffer.
		vim.api.nvim_command("botright vsplit BUILD_OUTPUT")

		-- Collect the buffer's number.
		buffer_number = vim.api.nvim_get_current_buf()

		-- Mark the buffer as readonly.
		vim.opt_local.readonly = true
	end
end

local function create_command(name, command, opts)
	vim.api.nvim_create_user_command(name, function()
		-- Open our buffer, if we need to.
		open_buffer()

		-- Clear the buffer's contents incase it has been used.
		vim.api.nvim_buf_set_lines(buffer_number, 0, -1, true, {})

		-- Run the command.
		vim.fn.jobstart(command, {
			stdout_buffered = false,
			on_stdout = log,
			on_stderr = log,
		})
	end, opts)
end

create_command(
	"Cmake",
	{ "cmake", "-S", cwd, "-B", cwd .. "/build", "-GNinja", "-DCMAKE_EXPORT_COMPILE_COMMANDS=True" },
	{ desc = "Run cmake on project" }
)

create_command("Ninja", { "ninja", "-C", "build" }, { desc = "Build project" })
