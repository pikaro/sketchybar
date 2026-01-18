local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_indices = {}

local workspaces = get_workspaces(nil, settings.space_order)

local focused_window = nil

local function get_focused_window()
	focused_window = runcmd("aerospace list-windows --focused --format '%{window-id}' | tr -d '\n'")
end

get_focused_window()

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

local function set_space_icons(ws_name, space)
	sbar.exec(
		"aerospace list-windows --workspace " .. ws_name .. " --format '%{app-name} %{window-id}' --json ",
		function(apps)
			local icon_line = ""
			local no_app = true
			for _, app in ipairs(apps) do
				no_app = false
				local app_name = app["app-name"]
				local lookup = app_icons[app_name]
				local icon = ((lookup == nil) and app_icons["default"] or lookup)
				if tostring(app["window-id"]) == focused_window then
					icon = "*" .. icon
				end
				icon_line = icon_line .. " " .. icon
			end

			if no_app then
				icon_line = ""
			end

			sbar.animate("tanh", 10, function()
				space:set({
					label = icon_line,
				})
			end)
		end
	)
end

for i, ws in ipairs(workspaces) do
	local bg = get_space_bg(ws.focused, ws.visible)
	local fg = get_space_fg(ws.focused, ws.visible)

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

	spaces[i] = space
	space_indices[ws.name] = i

	set_space_icons(ws.name, space)

	-- Item popup
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

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			space_popup:set({
				background = {
					image = "item." .. i,
				},
			})
			space:set({
				popup = {
					drawing = "toggle",
				},
			})
		else
			sbar.exec("aerospace workspace " .. ws.name)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		space:set({
			popup = {
				drawing = false,
			},
		})
	end)
end

local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

-- Handles the small icon indicator for spaces / menus changes
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

-- Event handles
space_window_observer:subscribe("space_windows_change", function()
	print("Space windows change detected")
	for i, ws in ipairs(workspaces) do
		set_space_icons(ws.name, spaces[i])
	end
end)

local function update_workspace(ws, monitor, focused, visible)
	local fg = get_space_fg(focused, visible)
	local bg = get_space_bg(focused, visible)

	ws:set({
		display = monitor,
		icon = {
			color = fg,
		},
		label = {
			color = fg,
		},
		background = {
			color = bg,
			border_color = fg,
			border_width = visible and 2 or 1,
		},
	})
end

space_window_observer:subscribe("aerospace_workspace_change", function()
	workspaces = get_workspaces(workspaces, settings.space_order)

	for _, ws in ipairs(workspaces) do
		local space = spaces[space_indices[ws.name]]

		if space == nil then
			print("Could not find workspace for: " .. ws.name)
		else
			update_workspace(space, ws.monitor, ws.focused, ws.visible)
		end
	end
end)

space_window_observer:subscribe("aerospace_focus_change", function()
	get_focused_window()
	for i, ws in ipairs(workspaces) do
		set_space_icons(ws.name, spaces[i])
	end
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
