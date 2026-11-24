-- Yazi user init: plugin setups that need to run on shell start.
-- Each plugin's keybinds (if any) live in keymap.toml, not here.

require("full-border"):setup()

require("git"):setup {
	order = 1500, -- linemode column ordering
}

require("mime-ext.local"):setup {
	-- Fall back to file(1) for unknown extensions so detection stays correct.
	fallback_file1 = true,
}
