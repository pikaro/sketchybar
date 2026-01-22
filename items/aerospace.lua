local json = require("cjson")

function runcmd(cmd)
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

function dump(o)
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

function explode(div, str)
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

function parse_string_to_table(s)
	local result = {}
	for line in s:gmatch("([^\n]+)") do
		table.insert(result, line)
	end
	return result
end

function get_workspaces(ws_old, ws_order)
	local result = runcmd(
		"aerospace list-workspaces --all --json --format '%{monitor-id} %{workspace} %{workspace-is-visible} %{monitor-appkit-nsscreen-screens-id} %{workspace-is-focused}'"
	)

	if result == "" then
		return ws_old or {}
	end

	local ws_json = json.decode(result)

	return get_workspaces_ordered(ws_json, ws_order)
end

function get_workspaces_ordered(workspaces, order)
	local rank = {}
	for i, prefix in ipairs(order) do
		rank[prefix] = i
	end

	local decorated = {}
	for i, ws in ipairs(workspaces) do
		local prefix = ws.workspace:match("^%s*(%S+)")
		ws["name"] = ws["workspace"]
		ws["focused"] = ws["workspace-is-focused"]
		ws["visible"] = ws["workspace-is-visible"]
		-- TODO: monitor-appkit-nsscreen-screens-id does NOT seem to match although issues
		--       suggest it does?
		ws["monitor"] = tostring(ws["monitor-id"])
		decorated[i] = { ws = ws, r = rank[prefix] or math.huge, i = i }
	end

	table.sort(decorated, function(a, b)
		if a.r ~= b.r then
			return a.r < b.r
		end
		return a.i < b.i
	end)

	local sorted = {}
	for i, d in ipairs(decorated) do
		sorted[i] = d.ws
	end

	return sorted
end
