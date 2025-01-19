local config = {
	DEFAULT_PLAYER_DATA = {
		towers = 0,
	},
	DATA_STORE_KEY = "Production",
	TOWER_STAT_NAME = "Towers",
	
	RESTART_COOLDOWN = 3,

	USE_DISPLAY_NAME = false,

	CHECKPOINTS_WORKSPACE_WARNING = true,
	CHECKPOINTS_MISSING_WARNING = true,
	NO_MINIMUM_TIME_WARNING = true,
	R15_WARNING = true,
}

export type PlayerData = typeof(config.DEFAULT_PLAYER_DATA)

return config
