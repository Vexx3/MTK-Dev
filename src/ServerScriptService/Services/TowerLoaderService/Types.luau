--[=[
@class Types
MTK makes extensive use of Luau’s type definitions to organize data, many of which act as data structures for various types of objects. This section of the document focuses on documenting every property of these structures; As well as describing other types that may be present in the scripts.
Almost every custom type used by MTK can be found in `MultiTowerServer.Types`. Furthermore, because of how extensively MTK makes use of type annotations, it is recommended that you at least have a basic understanding of Roblox Luau type annotating
]=]

--- @type List<T> {[number]:T }
--- @within Types
--- Represents a simple ordered array of items, essentially an alias of {[number]:T} (or {T}).
export type List<T> = { [number]: T }

--- @type Dictionary<T> {[string]:T}
--- @within Types
--- Same as `List<T>`, but uses `string` indexes instead of `number` indexes.
export type Dictionary<T> = { [string]: T }

--[=[
@interface PlayerInfo
@within Types
.Player Player -- A reference to the actual player instance in the **Players** service that this **PlayerInfo** is related to.
.GameTimer number -- In seconds, how long the player has been in the game. This value is floored and sent to the leaderboard every second for the **“Time”** statistic.
.LastRestart number -- How many seconds has passed since the player has last restarted a tower. This property is necessary for making sure they can’t lag out the server by imposing a cool-down. This cool-down duration can be changed in the game config via the **RestartCooldown**.
.CurrentTower string -- The ID of the tower the player is currently playing. If the player is not in a tower, this value will be blank.
.CurrentTowerCheckpoint number -- The index of the checkpoint the player is currently assigned to touch. Every time the appropriate checkpoint is touched, this value increments. If the referenced checkpoint does not exist, no checkpoint checks are done. If a player equips any debug items, this value is set to *math.huge*.
.BoostItemsUsed boolean -- Tracks whether or not a boost item has been used in a tower or tower rush. Whenever a player loads in a tower, this value is reset to false, but the moment they equip a boost item, this value is set to true.
.TowerTimer number -- In seconds, how long the player has been in a tower or tower rush. This value does not increment if the **CurrentTower** is blank; In other words, not currently in a tower. Although the client also keeps time for the same reason on it’s own, this value is sent to the client every 2 seconds to prevent the client’s timer from desynchronizing with the server’s timer.
.CurrentTowerRush string -- The ID of the tower rush the player is currently playing. If the player is not in a tower rush, this value will be blank. This value should ideally only be set if **CurrentTower** is also set.
.CurrentTowerRushIndex number -- The index of the current tower the player is at in the tower rush.
.TouchEventBusy boolean -- This boolean is used internally by various callbacks as a debounce for touch events.
.IsLoadingTower boolean -- This boolean is used as a debounce for tower loading. This property is set to true when a tower begins loading and reverts to false when it is finished. The loading of a tower cannot be initialized while this property is true.
.HasEverpresentCOs boolean -- This boolean is used to determine if the player has already been sent ever-present client objects. If this value is true, the client’s requests for ever-present COs will be rejected to prevent malicious users from lagging out the server.
]=]
export type PlayerInfo = {
	Player: Player,
	GameTimer: number,
	LastRestart: number,
	CurrentTower: string,
	CurrentTowerCheckpoint: number,
	BoostItemNames: Dictionary<string>,
	BoostItemUsed: boolean,
	TowerTimer: number,
	CurrentTowerRush: string,
	CurrentTowerRushIndex: number,
	TouchEventBusy: boolean,
	IsLoadingTower: boolean,
	HasEverpresentCOs: boolean,
	DebugItemUsed: boolean,
}

export type EndingInfo = {
	Name: string,
	Difficulty: string,
	BadgeID: number,
	PreventTowerBadge: boolean,
	ParentTower: string,
	WinroomMarker: string,
}

export type TowerInfo = {
	Name: string,
	Difficulty: string,
	BadgeID: number,
	Folder: Instance,
	SpawnLocation: BasePart,
	ClientObjects: Instance?,
	Endings: Dictionary<EndingInfo>,
	MinimumTime: number,
	Checkpoints: List<BasePart>,
	CheckpointCount: number,
}

export type TowerRush = {
	BadgeID: number,
	Title: string,
	Difficulty: string,
	WinroomMarker: string,
	Towers: List<string>,
}

export type DifficultyInfo = {
	Rating: number,
	Title: string,
	FancyFont: boolean,
	Color: Color3,
	GlobalAnnouncement: boolean,
}

return nil
