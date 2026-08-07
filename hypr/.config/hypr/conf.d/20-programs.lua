-- Program aliases
--
-- These are deliberately GLOBAL, not local. In the old hyprlang config
-- "source" was a textual include, so $mainMod and friends were visible
-- everywhere. Lua's require() gives each module its own scope, so a "local"
-- here would be nil in 60-binds.lua and every bind using it would fail.

terminal = "kitty"
fileManager = terminal .. " -e yazi"
mainMod = "SUPER"

-- Browser — change --profile-directory to "Profile 1" / "Profile 2" / etc. to pick a chromium profile.
-- Profile dirs live in ~/.config/chromium/
-- (Currently unreferenced; kept because it was in the old config.)
browser = "chromium --profile-directory=Default"
