-- Equivalent to the working Hyprland 0.56.2 config, including Noctalia 4.7.7.
-- Resolve modules beside this file so the staged config can be checked safely.
local source = debug.getinfo(1, "S").source
assert(source:sub(1, 1) == "@", "Cannot resolve Hyprland config directory")
local config_dir = assert(source:sub(2):match("^(.*)/[^/]+$"))
package.path = config_dir .. "/conf.d/?.lua;" .. config_dir .. "/?.lua;" .. package.path

require("00-monitors")
require("10-env")
require("20-programs")
require("30-autostart")
require("40-look")
require("50-input")
require("60-binds")
require("70-rules")

-- Apply last, exactly as the existing generated color include does.
require("noctalia.colors")(config_dir .. "/noctalia/noctalia-colors.conf")
