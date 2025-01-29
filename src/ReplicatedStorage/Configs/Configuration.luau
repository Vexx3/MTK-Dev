local config = {
	DEFAULT_PLAYER_DATA = {
		towers = 0,
	},
	DATA_STORE_KEY = "Production",
	TOWER_STAT_NAME = "Towers",

	ADMINS = { 949649253 },

	TIMER_SYNC_INTERVAL = 2,
	CHECKPOINT_INTERVAL = 0.25,
	RESTART_COOLDOWN = 3,
	RESTART_RESETS_TOWER_RUSH = true,

	WINPAD_INTERVAL = 0.25,
	WINPADS_CHANGE_COLOR = true,
	WINPADS_CHANGE_MATERIAL = true,
	USE_DISPLAY_NAME = false,

	CHECKPOINTS_WORKSPACE_WARNING = true,
	CHECKPOINTS_MISSING_WARNING = true,
	NO_MINIMUM_TIME_WARNING = true,
	R15_WARNING = true,

	WIN_MESSAGE = "{PlayerName} has beaten {EndingName} in {Time}{BoostsUsed}",
	WIN_MESSAGE_BOOSTS_USED = ", Boosts used: {BoostList}",

	CHAT_FONT = "<font color='{FontColor}' size='{FontSize}' face='{FontFace}'>{Message}</font>",
	CHAT_CHANNEL = "RBXSystem",
	CHAT_FONT_FACE = "GothamBold",
	CHAT_FONT_SIZE = 14,
	CHAT_FANCY_FONT_FACE = "Bodoni",
	CHAT_FANCY_FONT_SIZE = 18,
}

export type PlayerData = typeof(config.DEFAULT_PLAYER_DATA)

return config
