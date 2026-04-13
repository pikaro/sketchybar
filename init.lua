-- Require the sketchybar module
---@diagnostic disable-next-line: lowercase-global
sbar = require("sketchybar")

-- require("trace_debug")

sbar.begin_config()
require("bar")
require("default")
require("items")
sbar.end_config()

sbar.event_loop()
