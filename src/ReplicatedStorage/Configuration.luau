local config = {
	DEFAULT_PLAYER_DATA = {
		towers = 0,
	},
	DATA_STORE_KEY = "Production",
	TOWER_STAT_NAME = "Towers",
}

export type PlayerData = typeof(config.DEFAULT_PLAYER_DATA)

return config
