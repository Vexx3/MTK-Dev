--[=[
@class Types
MTK makes extensive use of Luau’s type definitions to organize data, many of which act as data structures for various types of objects. This section of the document focuses on documenting every property of these structures; As well as describing other types that may be present in the scripts.
Almost every custom type used by MTK can be found in `MultiTowerServer.Types`. Furthermore, because of how extensively MTK makes use of type annotations, it is recommended that you at least have a basic understanding of [Roblox Luau type annotating](https://luau.org/typecheck).
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

--[=[
@interface EndingInfo
@within Types
.Name string -- The proper, human-readable name of this ending.
.Difficulty string -- The name of the difficulty classification of this specific ending, it must be the name of a difficulty defined in **GameData.Difficulties**. Otherwise, a **default** difficulty will be used instead when obtaining the **Difficulty** info.
.BadgeID number -- The ID of the badge to be awarded when this ending is triggered. If this value is set to 0, no badge will be awarded. Furthermore, this badge is separate from the tower’s badge, so if a tower’s badge, as well as this ending’s badge are both set, both badges will be awarded at the same time.
.PreventTowerBadge boolean -- As mentioned above, both the tower badge and this ending’s own badge are awarded at the same time. However, if you want to suppress the tower badge from being awarded, enable this property.
.ParentTower string -- The ID of the tower this ending belongs to.
.WinroomMarker string -- The name of the marker the player should teleport to when this ending is triggered. If omitted, it the player will be teleported to the **WinroomSpawn**.
]=]
export type EndingInfo = {
	Name: string,
	Difficulty: string,
	BadgeID: number,
	PreventTowerBadge: boolean,
	ParentTower: string,
	WinroomMarker: string,
}

--[=[
@interface TowerInfo
@within Types
.Name string -- The full, human-readable name of the tower. For example, if you have a tower folder named “ToH”, an appropriate value for this property would be “Tower of Hecc”.
.Difficulty string -- The name of the difficulty classification of this tower, it must be the name of a difficulty defined in **GameData.Difficulties**. Otherwise, a “default” difficulty will be used instead when obtaining the **Difficulty** info.
.BadgeID number -- The ID of the badge to award the player upon beating this tower. If the value is 0, no badge will be awarded.
.Folder Instance -- A reference to the folder representing the tower in the workspace. The name of this folder will be used as the internal ID for this tower.
.SpawnLocation BasePart -- A reference to the part representing the position where the player should spawn upon entering the tower. Do not use an actual SpawnLocation, as it isn’t necessary and is prone to breaking the game, just use a regular part.
.ClientObjects Instance? -- A reference to the folder containing the tower’s client objects. If the tower does not contain a ClientSidedObjects folder, this property will be set to nil, and the tower will be marked as “Purist”.
.Endings Dictionary<EndingInfo> -- A dictionary of endings for this tower. The string keys represent the names of the endings, while the values contain information about the endings.
.MinimumTime number -- The minimum amount of time (measured in seconds) that the player must spend in a tower before they can touch the winpad, otherwise, they will be kicked from the game. Setting this value to 0 effectively disables this measure.
.Checkpoints List<BasePart> -- An ordered list of checkpoints, that must be touched by the player’s pivot point in order to complete the tower. Failing to touch each checkpoint will result in the player being kicked.
.CheckpointCount number -- Describes how many checkpoints the tower has. This property is figured out automatically and is used internally.
]=]
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

--[=[
@interface TowerRush
@within Types
.BadgeID number -- The ID of the badge to award the player upon beating this tower. If the value is 0, no badge will be awarded.
.Title string -- The full, human-readable name of the tower. For example, if you have a tower folder named “ToH”, an appropriate value for this property would be “Tower of Hecc”.
.Difficulty string -- The name of the difficulty classification of this specific ending, it must be the name of a difficulty defined in **GameData.Difficulties**. Otherwise, a **default** difficulty will be used instead when obtaining the **Difficulty** info.
.WinroomMarker string -- The name of the marker the player should teleport to when this ending is triggered. If omitted, it the player will be teleported to the **WinroomSpawn**.
.Towers List<string> -- A list of every tower that the player must progress through in the tower rush, in order of progression.
]=]
export type TowerRush = {
	BadgeID: number,
	Title: string,
	Difficulty: string,
	WinroomMarker: string,
	Towers: List<string>,
}

--[=[
@interface DifficultyInfo
@within Types
.Rating number -- The difficulty’s baseline represented as a number. In JToH, Easy is 1, and Catastrophic is 11.
.Title string -- The proper name of this difficulty. If the ID name of this difficulty is “ATrulyHardDifficulty”, a good title would be “A Truly Hard Difficulty”.
.FancyFont boolean -- Determines if 20pt Bodoni should be used as the font when displaying a win message, instead of the standard 18pt Source Sans Bold. In JToH, Bodoni font win messages are used for Catastrophic difficulty and above.
.Color Color3 -- The color of this difficulty, normally used for win messages.
.GlobalAnnouncement boolean -- If set to true, victors of any tower/tower rush of this difficulty will have their win messages broadcast throughout the entire game, on other servers.
]=]
export type DifficultyInfo = {
	Rating: number,
	Title: string,
	FancyFont: boolean,
	Color: Color3,
	GlobalAnnouncement: boolean,
}

return nil
