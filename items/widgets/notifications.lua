local app_icons = require("helpers.app_icons")
local colors = require("colors")
local settings = require("settings")
local settings_system = require("settings_system")
local log = require("helpers.log")
local fun = require("helpers.fun")

local widgets = {}

local function run(app)
	sbar.exec("osascript -e 'tell application \"" .. app .. "\" to activate'")
end

local function get_count_lsapp(app)
	local result = fun.runcmd("lsappinfo -all info -only StatusLabel '" .. app .. "' 2>/dev/null")

	if not result or result == "" then
		return 0
	end

	-- Format: "StatusLabel"={ "label"="<count>" }

	local count = string.match(result, '"label"="([^"]+)"')

	return count or 0
end

local methods = {
	["Mail"] = get_count_lsapp,
	["Slack"] = get_count_lsapp,
	["Microsoft Outlook"] = get_count_lsapp,
	["Microsoft Teams"] = get_count_lsapp,
	["Microsoft To Do"] = get_count_lsapp,
	["Telegram"] = get_count_lsapp,
}

local function rpairs(t)
	return function(p, i)
		i = i - 1
		if i ~= 0 then
			return i, p[i]
		end
	end, t, #t + 1
end

local function get_count(app)
	if not methods[app] then
		-- FIXME: Include fallback for WhatsApp
		log.log(log.systems.notifications, log.levels.warning, "No notification method for app: " .. app)
		return nil
	end

	return methods[app](app)
end

local function update_count(app, widget)
	local count = get_count(app)
	log.log(log.systems.notifications, log.levels.debug, "App: " .. app .. ", Count: " .. tostring(count))

	if count then
		if (type(count) == "number" and count > 0) or (type(count) == "string" and count ~= "0" and count ~= "") then
			widget:set({
				label = {
					string = tostring(count),
					color = colors.red,
					drawing = true,
				},
				icon = {
					color = colors.red,
					drawing = true,
				},
				background = {
					drawing = true,
				},
				drawing = true,
			})
		else
			widget:set({
				label = {
					string = "0",
					color = colors.grey,
					drawing = settings.notifications_show_empty,
				},
				icon = {
					color = colors.grey,
					drawing = settings.notifications_show_empty,
				},
				background = {
					drawing = settings.notifications_show_empty,
				},
				drawing = settings.notifications_show_empty,
			})
		end
	else
		widget:set({
			label = {
				string = "?",
				color = colors.red,
				drawing = true,
			},
			icon = {
				color = colors.grey,
				drawing = true,
			},
			background = {
				drawing = true,
			},
			drawing = true,
		})
	end
end

local function add_widget(app)
	widgets[app] = sbar.add("item", "widgets.notifications." .. app, {
		position = "right",
		update_freq = settings.notifications_interval,
		padding_left = 2,
		padding_right = 2,
		icon = {
			string = app_icons[app] or app_icons["Default"],
			align = "left",
			color = colors.grey,
			font = settings.icons,
			padding_left = 10,
			padding_right = 5,
		},
		label = {
			string = "?",
			padding_left = 5,
			padding_right = 10,
			font = {
				family = settings.font.numbers,
			},
		},
		background = {
			color = colors.black,
			border_color = colors.grey,
			border_width = 1,
		},
	})

	widgets[app]:subscribe("routine", function()
		log.log(log.systems.notifications, log.levels.debug, "Updating notification count for app: " .. app)
		update_count(app, widgets[app])
	end)

	widgets[app]:subscribe("mouse.clicked", function()
		log.log(log.systems.notifications, log.levels.debug, "Clicked notification widget for app: " .. app)
		run(app)
	end)

	log.log(log.systems.notifications, log.levels.info, "Added notification widget for app: " .. app)
end

-- combine settings.notifications and settings_system.notifications
local notifications = settings.notifications or {}
for _, app in ipairs(settings_system.notifications or {}) do
	table.insert(notifications, app)
end

for _, app in rpairs(notifications) do
	add_widget(app)
	update_count(app, widgets[app])
end
