local M = {}
local trace = require("helpers.trace")

local function assert_not_nil(name, value, message)
	if value == nil then
		error(message or (name .. " should not be nil"), 2)
	end
end
M.assert_not_nil = assert_not_nil

local function runcmd(cmd, callback)
	assert_not_nil("cmd", cmd)
	assert_not_nil("callback", callback, "runcmd requires a callback")
	local command_id = trace.shell_start(cmd, {
		source = "helpers.fun.runcmd",
	})

	sbar.exec(cmd, function(result, exit_code)
		trace.shell_done(command_id, exit_code, result, {
			source = "helpers.fun.runcmd",
		})

		if exit_code ~= 0 and (result == nil or result == "") then
			print("Error: command failed: " .. cmd .. " (exit " .. tostring(exit_code) .. ")")
		end

		callback(result or "", exit_code)
	end)
end
M.runcmd = runcmd

local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			local key = k
			if type(k) ~= "number" then
				key = '"' .. k .. '"'
			end
			s = s .. "[" .. key .. "] = " .. dump(v) .. ","
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
