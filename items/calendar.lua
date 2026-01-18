local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local cal = sbar.add("item", {
	icon = {
		color = colors.white,
		padding_left = 4,
		padding_right = 4,
		string = icons.calendar,
		font = {
			size = 16.0,
		},
	},
	label = {
		color = colors.white,
		padding_right = 8,
		width = 100,
		align = "right",
		font = {
			family = settings.font.text,
		},
	},
	position = "right",
	update_freq = 30,
	padding_left = 5,
	padding_right = 4,
	background = {
		color = colors.bg2,
		border_color = settings.rainbow and colors.rainbow[#colors.rainbow] or colors.no_rainbow,
		border_width = 1,
	},
})

cal:subscribe({ "forced", "routine", "system_woke" }, function()
	cal:set({
		label = os.date("%m-%d %H:%M"),
	})
end)
