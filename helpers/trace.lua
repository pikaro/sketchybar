local function noop(_, _, _, _) end

return {
	event = noop,
	shell_start = noop,
	shell_done = noop,
}
