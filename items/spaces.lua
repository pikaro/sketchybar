local log = require("helpers.log")
local fun = require("helpers.fun")
local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local aerospace = require("helpers.aerospace")
local trace = require("helpers.trace")

local spaces = {}
local workspaces = {}
local max_space_slots = math.max(#settings.space_order + 4, 12)
local display_map_ready = false
local initial_draw_complete = false
local startup_retry_attempts = 0
local max_startup_retry_attempts = 8

local focused_window = nil
local workspace_refresh_id = 0
local focus_refresh_id = 0

local function get_space_bg(focused, visible)
	if focused then
		return settings.items.colors.background_focused
	elseif visible then
		return settings.items.colors.background_visible
	else
		return settings.items.colors.background
	end
end

local function get_space_fg(focused, visible)
	if focused then
		return settings.items.colors.foreground_focused
	elseif visible then
		return settings.items.colors.foreground_visible
	else
		return settings.items.colors.foreground
	end
end

local function update_workspace(item, ws)
	local fg = get_space_fg(ws.focused, ws.visible)
	local bg = get_space_bg(ws.focused, ws.visible)
	local should_draw = display_map_ready

	item:set({
		drawing = true,
		display = ws.monitor,
		icon = {
			string = ws.name,
			color = should_draw and fg or { alpha = 0.0 },
		},
		label = {
			color = should_draw and fg or { alpha = 0.0 },
		},
		background = {
			color = should_draw and bg or { alpha = 0.0 },
			border_color = should_draw and fg or { alpha = 0.0 },
			border_width = should_draw and (ws.visible and 2 or 1) or 0,
		},
	})
end

local function update_placeholder_workspace(item, ws_name)
	item:set({
		drawing = true,
		display = 1,
		icon = {
			string = ws_name,
			color = { alpha = 0.0 },
		},
		label = {
			string = "",
			color = { alpha = 0.0 },
		},
		background = {
			color = { alpha = 0.0 },
			border_color = { alpha = 0.0 },
			border_width = 0,
		},
	})
end

local function set_space_icons(ws_name, space)
	fun.assert_not_nil("ws_name", ws_name)
	fun.assert_not_nil("space", space)
	if not display_map_ready then
		trace.event("spaces.set_space_icons.skipped", {
			workspace = ws_name,
			reason = "display_map_not_ready",
		})
		return
	end
	local command = "timeout 1 aerospace list-windows --workspace " .. ws_name .. " --format '%{app-name} %{window-id}' --json "
	local command_id = trace.shell_start(command, {
		source = "items.spaces.set_space_icons",
		workspace = ws_name,
	})
	trace.event("spaces.set_space_icons.start", {
		workspace = ws_name,
		space = space.name,
	})

	sbar.exec(
		command,
		function(apps)
			local icon_line = ""
			local app_list = type(apps) == "table" and apps or {}
			trace.shell_done(command_id, 0, "apps=" .. tostring(#app_list), {
				source = "items.spaces.set_space_icons",
				workspace = ws_name,
			})

			for _, app in ipairs(app_list) do
				local app_name = app["app-name"]
				local lookup = app_icons[app_name]
				local icon = ((lookup == nil) and app_icons["Default"] or lookup)
				if tostring(app["window-id"]) == focused_window then
					icon = "*" .. icon
				end
				icon_line = icon_line .. " " .. icon
			end

			sbar.animate("tanh", 10, function()
				space:set({
					label = icon_line,
				})
			end)
			trace.event("spaces.set_space_icons.done", {
				workspace = ws_name,
				apps = #app_list,
				focused_window = focused_window,
			})
		end
	)
end

local function refresh_space_icons()
	if not display_map_ready then
		trace.event("spaces.refresh_space_icons.skipped", {
			reason = "display_map_not_ready",
			workspaces = #workspaces,
		})
		return
	end
	trace.event("spaces.refresh_space_icons.start", {
		workspaces = #workspaces,
		slots = #spaces,
	})
	for i, ws in ipairs(workspaces) do
		local record = spaces[i]
		if record ~= nil then
			trace.event("spaces.refresh_space_icons.item", {
				index = i,
				workspace = ws.name,
				has_item = record.item ~= nil,
			})
			set_space_icons(ws.name, record.item)
		end
	end
	trace.event("spaces.refresh_space_icons.done", {
		workspaces = #workspaces,
	})
end

local function create_space(i, ws, placeholder)
	trace.event("spaces.create_space", {
		index = i,
		workspace = ws.name,
		monitor = ws.monitor,
		placeholder = placeholder,
	})
	local fg = get_space_fg(ws.focused, ws.visible)
	local bg = get_space_bg(ws.focused, ws.visible)
	local record = {
		name = ws.name,
	}

	local space = sbar.add("item", "item." .. i, {
		display = ws.monitor,
		icon = {
			font = {
				family = settings.font.numbers,
			},
			string = ws.name,
			padding_left = settings.items.padding.left,
			padding_right = settings.items.padding.left / 2,
			color = fg,
		},
		label = {
			font = settings.icons,
			y_offset = -1,
			padding_right = settings.items.padding.right,
			color = fg,
		},
		padding_right = 1,
		padding_left = 1,
		background = {
			color = bg,
			border_color = fg,
			border_width = ws.visible and 2 or 1,
			height = settings.items.height,
		},
		popup = {
			background = {
				border_width = 5,
				border_color = colors.black,
			},
		},
	})

	local space_popup = sbar.add("item", {
		position = "popup." .. space.name,
		padding_left = 5,
		padding_right = 0,
		background = {
			drawing = true,
			image = {
				corner_radius = 9,
				scale = 0.2,
			},
		},
	})

	record.item = space
	record.popup = space_popup
	spaces[i] = record

	if placeholder then
		update_placeholder_workspace(record.item, ws.name)
	end

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			record.popup:set({
				background = {
					image = "item." .. i,
				},
			})
			record.item:set({
				popup = {
					drawing = "toggle",
				},
			})
		else
			sbar.exec("aerospace workspace " .. record.name)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		record.item:set({
			popup = {
				drawing = false,
			},
		})
	end)

	return record
end

local function sync_spaces()
	trace.event("spaces.sync.start", {
		workspaces = #workspaces,
		existing = #spaces,
	})
	for i, ws in ipairs(workspaces) do
		local record = spaces[i] or create_space(i, ws)
		record.name = ws.name
		update_workspace(record.item, ws)
	end

	for i = #workspaces + 1, #spaces do
		spaces[i].item:set({
			drawing = false,
		})
	end
	trace.event("spaces.sync.done", {
		workspaces = #workspaces,
		existing = #spaces,
	})
end

local function refresh_focused_window(callback)
	focus_refresh_id = focus_refresh_id + 1
	local request_id = focus_refresh_id
	trace.event("spaces.refresh_focused_window.start", {
		request_id = request_id,
	})

	fun.runcmd("aerospace list-windows --focused --format '%{window-id}' | tr -d '\n'", function(result)
		if request_id ~= focus_refresh_id then
			trace.event("spaces.refresh_focused_window.stale", {
				request_id = request_id,
				current = focus_refresh_id,
			})
			return
		end

		focused_window = tostring(result or ""):gsub("%s+$", "")
		trace.event("spaces.refresh_focused_window.done", {
			request_id = request_id,
			focused_window = focused_window,
		})
		if callback then
			trace.event("spaces.refresh_focused_window.callback", {
				request_id = request_id,
				callback = "present",
			})
			callback()
		else
			trace.event("spaces.refresh_focused_window.callback", {
				request_id = request_id,
				callback = "missing",
			})
		end
	end)
end

local function refresh_workspaces(rebuild_display_map, callback)
	workspace_refresh_id = workspace_refresh_id + 1
	local request_id = workspace_refresh_id
	trace.event("spaces.refresh_workspaces.start", {
		request_id = request_id,
		rebuild_display_map = rebuild_display_map,
		current_workspaces = #workspaces,
	})

	local function on_workspaces(new_workspaces)
		if request_id ~= workspace_refresh_id then
			trace.event("spaces.refresh_workspaces.stale", {
				request_id = request_id,
				current = workspace_refresh_id,
			})
			return
		end

		workspaces = new_workspaces or {}
		sync_spaces()
		if display_map_ready then
			initial_draw_complete = true
		end
		trace.event("spaces.refresh_workspaces.done", {
			request_id = request_id,
			workspaces = #workspaces,
		})
		if callback then
			trace.event("spaces.refresh_workspaces.callback", {
				request_id = request_id,
				callback = "present",
			})
			callback()
		else
			trace.event("spaces.refresh_workspaces.callback", {
				request_id = request_id,
				callback = "missing",
			})
		end
	end

	local function fetch_workspaces()
		aerospace.get_workspaces(workspaces, settings.space_order, on_workspaces)
	end

	if rebuild_display_map then
		aerospace.build_display_map(function(display_map)
			if request_id ~= workspace_refresh_id then
				trace.event("spaces.refresh_workspaces.display_map_stale", {
					request_id = request_id,
					current = workspace_refresh_id,
				})
				return
			end
			if display_map == nil then
				log.log(log.systems.aerospace, log.levels.error, "Display map refresh failed")
				trace.event("spaces.refresh_workspaces.display_map_failed", {
					request_id = request_id,
				})
				if not initial_draw_complete and startup_retry_attempts < max_startup_retry_attempts then
					startup_retry_attempts = startup_retry_attempts + 1
					local attempt = startup_retry_attempts
					trace.event("spaces.startup_retry.scheduled", {
						attempt = attempt,
						delay_seconds = attempt,
					})
					sbar.delay(attempt, function()
						trace.event("spaces.startup_retry.fired", {
							attempt = attempt,
						})
						refresh_workspaces(true, function()
							refresh_focused_window(refresh_space_icons)
						end)
					end)
				end
				fetch_workspaces()
				return
			end
			display_map_ready = true
			trace.event("spaces.refresh_workspaces.display_map_done", {
				request_id = request_id,
				has_display_map = true,
			})
			fetch_workspaces()
		end)
	else
		fetch_workspaces()
	end
end

for i = 1, max_space_slots do
	local placeholder_name = settings.space_order[i] or tostring(i)
	create_space(i, {
		name = placeholder_name,
		focused = false,
		visible = false,
		monitor = 1,
	}, true)
end

local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

local spaces_indicator = sbar.add("item", {
	display = 1,
	padding_left = -3,
	padding_right = 0,
	icon = {
		padding_left = 8,
		padding_right = 9,
		color = colors.grey,
		string = icons.switch.on,
	},
	label = {
		width = 0,
		padding_left = 0,
		padding_right = 8,
		string = "Spaces",
		color = colors.bg1,
	},
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
	},
})

space_window_observer:subscribe("space_windows_change", function()
	trace.event("spaces.event.space_windows_change", {})
	refresh_space_icons()
end)

space_window_observer:subscribe("aerospace_workspace_change", function()
	trace.event("spaces.event.aerospace_workspace_change", {})
	refresh_workspaces(false, refresh_space_icons)
end)

space_window_observer:subscribe("aerospace_focus_change", function()
	trace.event("spaces.event.aerospace_focus_change", {})
	refresh_focused_window(refresh_space_icons)
end)

space_window_observer:subscribe({ "system_woke", "forced" }, function(env)
	trace.event("spaces.event.refresh", {
		name = env.NAME,
		sender = env.SENDER,
	})
	refresh_workspaces(true, function()
		refresh_focused_window(refresh_space_icons)
	end)
end)

space_window_observer:subscribe("display_change", function()
	trace.event("spaces.event.display_change", {})
	refresh_workspaces(true, function()
		refresh_focused_window(refresh_space_icons)
	end)
end)

spaces_indicator:subscribe("swap_menus_and_spaces", function()
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)
spaces_indicator:subscribe("mouse.entered", function()
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = {
					alpha = 1.0,
				},
				border_color = {
					alpha = 1.0,
				},
			},
			icon = {
				color = colors.bg1,
			},
			label = {
				width = "dynamic",
			},
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function()
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = {
					alpha = 0.0,
				},
				border_color = {
					alpha = 0.0,
				},
			},
			icon = {
				color = colors.grey,
			},
			label = {
				width = 0,
			},
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function()
	sbar.trigger("swap_menus_and_spaces")
end)

refresh_workspaces(true, function()
	refresh_focused_window(refresh_space_icons)
end)
