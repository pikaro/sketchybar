local M = {}

local function assert_not_nil(name, value, message)
	if value == nil then
		error(message or (name .. " should not be nil"), 2)
	end
end
M.assert_not_nil = assert_not_nil

local function runcmd(cmd)
	local handle = io.popen(cmd .. " 2>&1 | head -c 65536", "r")
	if handle == nil then
		print("Error: could not execute command: " .. cmd)
		return ""
	end

	local result = handle:read("*a")
	-- FIXME: Hangs in close() randomly despite no child processes actually running
	--        Is waiting for nonexistent low PID like 4 - memory corruption?
	--        Apparent deadlock with mach2_read for IPC to CPU/network usage?
	--        Lua GC should clean up FDs and even with rapid switching, no apparent
	--        persistent leakage.

	-- local ok, reason, code = handle:close()
	-- if not ok then
	-- 	print("Error: failed: ok=" .. tostring(ok) .. ", reason=" .. tostring(reason) .. ", code=" .. tostring(code))
	-- end

	return result
end
M.runcmd = runcmd

local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end
M.dump = dump

local function explode(div, str)
	if div == "" then
		return false
	end
	local pos, arr = 0, {}
	for st, sp in
		function()
			return string.find(str, div, pos, true)
		end
	do
		table.insert(arr, string.sub(str, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(str, pos))
	return arr
end
M.explode = explode

local function parse_string_to_table(s)
	local result = {}
	for line in s:gmatch("([^\n]+)") do
		table.insert(result, line)
	end
	return result
end
M.parse_string_to_table = parse_string_to_table

return M
