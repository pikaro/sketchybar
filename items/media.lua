local settings = require("settings")
local icons = require("icons")
local app_icons = require("helpers.app_icons")
local colors = require("colors")
local b64 = require("helpers.b64")
local json = require("cjson")

-- local media_cover = sbar.add("item", {
-- 	position = "right",
-- 	label = {
-- 		drawing = false,
-- 	},
-- 	icon = {
-- 		drawing = false,
-- 	},
-- 	drawing = false,
-- 	updates = true,
-- 	popup = {
-- 		align = "center",
-- 		horizontal = true,
-- 		background = {
-- 			image = {
-- 				string = "/tmp/sketchybar_cover_artwork",
-- 				scale = 0.85,
-- 			},
-- 			color = colors.transparent,
-- 		},
-- 	},
-- })

sbar.add("item", "widgets.media.padding", {
	position = "right",
	width = 5,
})

local next = sbar.add("item", {
	position = "right",
	icon = {
		padding_left = 0,
		padding_right = 5,
		string = icons.media.forward,
		color = settings.colors.media_buttons,
	},
	label = {
		drawing = false,
	},
	click_script = "media-control next-track",
})

local play = sbar.add("item", {
	position = "right",
	icon = {
		padding_left = 4,
		padding_right = 4,
		string = icons.media.play,
		color = settings.colors.media_buttons,
	},
	label = {
		drawing = false,
	},
	click_script = "media-control toggle-play-pause",
})

local prev = sbar.add("item", {
	position = "right",
	icon = {
		padding_left = 2,
		padding_right = 0,
		string = icons.media.back,
		color = settings.colors.media_buttons,
	},
	label = {
		drawing = false,
	},
	click_script = "media-control previous-track",
})

local bundles = {
	["ch.laurinbrandner.nuage"] = "Nuage",
	["com.apple.Music"] = "Music",
	["com.spotify.client"] = "Spotify",
}

local app = sbar.add("item", {
	position = "right",
	icon = {
		padding_left = 2,
		padding_right = 2,
		string = "",
		color = settings.colors.media_buttons,
		font = settings.icons,
	},
	label = {
		drawing = false,
	},
	click_script = "media-control next-track",
})

local media_artist = sbar.add("item", {
	position = "right",
	drawing = false,
	padding_left = 3,
	padding_right = 0,
	width = 0,
	icon = {
		drawing = false,
	},
	label = {
		width = 0,
		font = {
			size = 9,
		},
		max_chars = settings.media.max_chars,
		y_offset = 6,
		color = settings.colors.media_buttons,
	},
})

local media_title = sbar.add("item", {
	position = "right",
	drawing = false,
	padding_left = 3,
	padding_right = 0,
	icon = {
		drawing = false,
	},
	label = {
		font = {
			size = 11,
		},
		width = 0,
		max_chars = settings.media.max_chars,
		y_offset = -5,
		color = settings.colors.media_buttons,
	},
})

local bracket = sbar.add("bracket", { media_artist.name, media_title.name, prev.name, play.name, next.name }, {
	position = "right",
	background = {
		padding_right = 5,
		color = colors.bg1,
		corner_radius = 4,
	},
})

local function animate_detail(detail)
	sbar.animate("tanh", 30, function()
		media_artist:set({
			label = {
				width = detail and "dynamic" or 0,
			},
		})
		media_title:set({
			label = {
				width = detail and "dynamic" or 0,
			},
		})
	end)
end

play:subscribe("media_control_update", function(env)
	print("[media] Received media control update")

	local data = b64.decode(env.DATA)
	if not data or data == "" then
		print("[media] No data received")
		return
	end

	local decoded = json.decode(data)
	if not decoded then
		print("[media] Failed to decode JSON")
		return
	end

	local payload = decoded.payload
	if not payload then
		print("[media] No payload in data")
		return
	end

	local artist = payload.artist
	local title = payload.title
	local playing = payload.playing
	local bundle = payload.bundleIdentifier

	if artist then
		print("Artist:", artist)
		media_artist:set({
			drawing = true,
			label = {
				string = artist,
			},
		})
	end

	if title then
		print("Title:", title)
		media_title:set({
			drawing = true,
			label = {
				string = title,
			},
		})
	end

	if bundle then
		local app_name = bundles[bundle]
		if app_name then
			local icon = app_icons[app_name] or app_icons["Default"]
			app:set({
				icon = {
					string = icon,
				},
			})
		end
	end

	if playing ~= nil then
		animate_detail(playing)
		sbar.delay(5, animate_detail)

		if playing then
			play:set({
				icon = {
					string = icons.media.pause,
				},
			})
		else
			play:set({
				icon = {
					string = icons.media.play,
				},
			})
		end
	end
end)

bracket:subscribe("mouse.entered", function()
	animate_detail(true)
end)

bracket:subscribe("mouse.exited.global", function()
	sbar.delay(2, animate_detail)
end)
