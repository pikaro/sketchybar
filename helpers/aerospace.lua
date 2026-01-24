local log = require("helpers.log")
local json = require("cjson")
local fun = require("helpers.fun")

local M = {}

-- map[DirectDisplayID] = arrangement-id
local display_map = nil

local function build_display_map()
	log.log(log.systems.aerospace, log.levels.info, "Rebuilding display map")

	local out = fun.runcmd("sketchybar --query displays")
	if out == "" then
		log.log(log.systems.aerospace, log.levels.error, "Failed to get display info from sketchybar")
		return
	end

	local displays = json.decode(out)
	if displays == nil then
		log.log(log.systems.aerospace, log.levels.error, "Failed to decode display info JSON from sketchybar")
		return
	end

	local dm = {}

	for _, d in ipairs(displays) do
		local id = d.DirectDisplayID
		if id ~= nil then
			log.log(
				log.systems.aerospace,
				log.levels.debug,
				"Mapping display ID " .. tostring(id) .. " to arrangement ID " .. tostring(d["arrangement-id"])
			)
			dm[id] = d["arrangement-id"]
		else
			log.log(
				log.systems.aerospace,
				log.levels.warn,
				"Display " .. tostring(d["arrangement-id"]) .. " without DirectDisplayID found in sketchybar output"
			)
		end
	end

	display_map = dm
end
build_display_map()
M.build_display_map = build_display_map

local function get_workspaces(ws_old, ws_order)
	local result = fun.runcmd(
		"aerospace list-workspaces --all --json --format '%{monitor-id} %{workspace} %{workspace-is-visible} %{monitor-appkit-nsscreen-screens-id} %{workspace-is-focused}'"
	)

	if result == "" then
		log.log(log.systems.aerospace, log.levels.error, "Failed to get workspaces from aerospace")
		return ws_old or {}
	end

	local ws_json = json.decode(result)

	return M.get_workspaces_ordered(ws_json, ws_order)
end
M.get_workspaces = get_workspaces

local function get_workspaces_ordered(workspaces, order)
	local rank = {}
	for i, prefix in ipairs(order) do
		rank[prefix] = i
	end

	local dm = display_map
	if dm == nil then
		log.log(log.systems.aerospace, log.levels.error, "Display map is nil")
		return workspaces
	end

	local decorated = {}
	for i, ws in ipairs(workspaces) do
		local prefix = ws.workspace:match("^%s*(%S+)")
		ws["name"] = ws["workspace"]
		ws["focused"] = ws["workspace-is-focused"]
		ws["visible"] = ws["workspace-is-visible"]
		ws["monitor"] = dm[ws["monitor-appkit-nsscreen-screens-id"]]
		log.log(
			log.systems.aerospace,
			log.levels.debug,
			"Workspace "
				.. ws["name"]
				.. ", visible: "
				.. tostring(ws["visible"])
				.. ", focused: "
				.. tostring(ws["focused"])
				.. ", monitor: "
				.. tostring(ws["monitor"])
				.. " (nsscreen: "
				.. tostring(ws["monitor-appkit-nsscreen-screens-id"])
				.. ", id: "
				.. tostring(ws["monitor-id"])
				.. ")"
		)
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
M.get_workspaces_ordered = get_workspaces_ordered

return M
