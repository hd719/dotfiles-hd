-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- my coolnight colorscheme
config.colors = {
	foreground = "#cdd6f4",
	background = "#282a36",
	cursor_bg = "#47FF9C",
	cursor_border = "#47FF9C",
	cursor_fg = "#011423",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = {
		"#282a36",  -- black
		"#ff5c57",  -- maroon (red)
		"#5af78e",  -- green
		"#f3f99d",  -- olive (yellow)
		"#57c7ff",  -- navy (blue)
		"#ff6ac1",  -- purple (magenta)
		"#9aedfe",  -- teal (cyan)
		"#f1f1f0",  -- silver (white)
	},
	brights = {
		"#686868",  -- grey (bright black)
		"#ff5c57",  -- red (bright red)
		"#5af78e",  -- lime (bright green)
		"#f3f99d",  -- yellow (bright yellow)
		"#57c7ff",  -- blue (bright blue)
		"#ff6ac1",  -- fuchsia (bright magenta)
		"#9aedfe",  -- aqua (bright cyan)
		"#f1f1f0",  -- white (bright white)
	},
}

config.font = wezterm.font("Hasklug Nerd Font Propo")
config.font_size = 15
config.enable_tab_bar = false
config.tab_bar_at_bottom = true
config.window_decorations = "RESIZE"
-- config.window_background_opacity = .90
-- config.macos_window_background_blur = 50
config.max_fps = 120
config.default_cursor_style = 'BlinkingBlock'
config.underline_thickness = 3.0
config.animation_fps = 1
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'
-- Key bindings to switch tabs with Control + Shift + H/L
config.keys = {
	{
		key = 'f',
		mods = 'OPT',
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = 'v',
		mods = 'OPT',
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		key = 'g',
		mods = 'OPT',
		action = wezterm.action.SplitHorizontal{domain="CurrentPaneDomain"},
	},
	{
		key = 'b',
		mods = 'OPT',
		action = wezterm.action.SplitVertical{domain="CurrentPaneDomain"},
	},
}

-- and finally, return the configuration to wezterm
return config
