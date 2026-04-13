local M = {}

local trace_path = os.getenv("SKETCHYBAR_TRACE_FILE") or "/tmp/sketchybar-trace.log"
math.randomseed(os.time())

local function make_id()
	return string.format(
		"%08x-%04x-%04x-%04x-%04x%08x",
		math.random(0, 0xffffffff),
		math.random(0, 0xffff),
		math.random(0, 0xffff),
		math.random(0, 0xffff),
		math.random(0, 0xffff),
		math.random(0, 0xffffffff)
	)
end

local session_id = string.format(
	"%s",
	make_id()
)

local function sanitize(value)
	if value == nil then
		return "nil"
	end

	local s = tostring(value)
	s = s:gsub("\n", "\\n")
	s = s:gsub("\r", "\\r")
	return s
end

local function write_line(kind, name, fields)
	local file = io.open(trace_path, "a")
	if file == nil then
		return
	end

	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local parts = {
		timestamp,
		string.format("%.3f", os.clock()),
		"session=" .. session_id,
		kind,
		name,
	}

	if fields ~= nil then
		for k, v in pairs(fields) do
			table.insert(parts, k .. "=" .. sanitize(v))
		end
	end

	file:write(table.concat(parts, " | "), "\n")
	file:close()
end

function M.event(name, fields)
	write_line("event", name, fields)
end

function M.shell_start(cmd, fields)
	local command_id = make_id()
	local payload = fields or {}
	payload.cmd = cmd
	payload.command_id = command_id
	write_line("shell_start", "command", payload)
	return command_id
end

function M.shell_done(command_id, exit_code, result, fields)
	local payload = fields or {}
	payload.command_id = command_id
	payload.exit_code = exit_code
	payload.result = result
	write_line("shell_done", "command", payload)
end

write_line("trace", "enabled", {
	path = trace_path,
	session_id = session_id,
	pid = os.getenv("SKETCHYBAR_PID") or "unknown",
})
M.session_id = session_id
M.event("session_start", {
	session_id = session_id,
})

return M
