local const = require("helpers.const")
local settings = require("settings")

local level_names = {
	"dbg",
	"inf",
	"wrn",
	"err",
}

settings.log_level = const.log_levels.info

local function do_log(system, level, message)
	if level < settings.log_level then
		return
	end

	local now = os.date("%Y-%m-%d %H:%M:%S")
	local level_str = level_names[level] or "UNK"

	print(string.format("[%s] [%s] [%s]: %s", now, system, level_str, message))
end

return {
	systems = {
		main = " M ",
		media = "med",
		notifications = "ntf",
	},
	levels = const.log_levels,
	log = do_log,
}
