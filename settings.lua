local colors = require("colors")
local icons = require("icons")

return {
	rainbow = false,
	paddings = 3,
	group_paddings = 5,

	modes = {
		main = {
			icon = icons.rebel,
			color = colors.rainbow[1],
		},
		service = {
			icon = icons.nuke,
			color = 0xffff9e64,
		},
	},

	bar = {
		height = 36,
		padding = {
			x = 5,
			y = 0,
		},
		background = colors.bar.bg,
	},

	items = {
		height = 26,
		gap = 5,
		padding = {
			right = 8,
			left = 6,
			top = 0,
			bottom = 0,
		},

		colors = {
			background = colors.black,
			background_visible = colors.bg2,
			background_focused = colors.bg3,
			foreground = colors.grey,
			foreground_visible = colors.fg3,
			foreground_focused = colors.fg1,
		},
		corner_radius = 4,
	},

	colors = {
		front_app = colors.black,
	},

	notifications = {
		"Mail",
		"Slack",
	},

	notifications_interval = 10,
	notifications_show_empty = false,

	space_order = { "k", "w", "c", "t", "m", "s", "1", "2", "a" },

	icons = "sketchybar-app-font:Regular:14.0", -- alternatively available: NerdFont

	font = {
		text = "FiraCode Nerd Font Mono", -- Used for text
		numbers = "FiraCode Nerd Font Mono", -- Used for numbers
		style_map = {
			["Regular"] = "Regular",
			["Semibold"] = "Medium",
			["Bold"] = "SemiBold",
			["Heavy"] = "Bold",
			["Black"] = "ExtraBold",
		},
	},
}
