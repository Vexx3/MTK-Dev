local BadgeService = game:GetService("BadgeService")
local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local Teams = game:GetService("Teams")

local Configs = ReplicatedStorage.Configs
local Announcements = require(script.Announcements)
local Configuration = require(Configs.Configuration)
local Types = require(ReplicatedStorage.Shared.Types)
local TowerRushes = require(Configs.TowerRushes)
local Util = require(script.Util)
local WinpadMaterials = require(script.WinpadMaterials)

type Dictionary<T> = Types.Dictionary<T>
type List<T> = Types.List<T>
type EndingInfo = Types.EndingInfo
type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo
type TowerRush = Types.TowerRush
type Difficulty = Types.DifficultyInfo
type TouchOptions = {
	TowerName: string?,
	EndingID: string?,
	isMarker: boolean?,
	portal: { normal: boolean?, towerRush: { towerRushName: string }?, lobbyTeleporter: { targetPart: BasePart }? }?,
}

local TowerFolder: Folder = workspace.Towers
local PortalFolder: Folder = workspace.Portals
local Markers: Folder = workspace.Markers
local RemotesFolder = ReplicatedStorage.Remotes.TowerGame
local ClientObjectsFolder = ServerStorage.TowerClientObjects
local TowerCheckpointsFolder = ServerStorage.TowerCheckpoints
local WinpadParticles: ParticleEmitter = ServerStorage.WinpadParticles
local StarterPackStudio: Folder = ServerStorage.StarterPackStudio
local EverpresentCOs = TowerFolder:WaitForChild("EverpresentCOs")

local RemoteEvents: Dictionary<RemoteEvent> = {}
local RemoteFunctions: Dictionary<RemoteFunction> = {}

local LEGACY_TOWER_RUSHES = 0

do
	for _, v: Instance in RemotesFolder:GetChildren() do
		if v:IsA("RemoteEvent") then
			RemoteEvents[v.Name] = v
		elseif v:IsA("RemoteFunction") then
			RemoteFunctions[v.Name] = v
		end
	end
end

local Towers: Dictionary<TowerInfo> = {}
local Players: Dictionary<PlayerInfo> = {}
local Winpads: List<BasePart> = {}

--- @class MultiTowerServer
--- Handles the loading of towers, winpads, and portals.
local Local = {}
local Shared = {}

function Shared.OnStart()
	PlayersService.PlayerAdded:Connect(Local.onPlayerAdded)
	PlayersService.PlayerRemoving:Connect(Local.onPlayerRemoving)
	RemoteEvents.RestartRequested.OnServerEvent:Connect(Local.PlayerRequestedRestart)
	RemoteFunctions.RequestEverpresentCOs.OnServerInvoke = Local.EverpresentCOsRequested
	RunService.Stepped:Connect(Local.onStepped)

	do
		if RunService:IsStudio() then
			for _, tool in StarterPackStudio:GetChildren() do
				tool:SetAttribute("DebugItem", true)
				tool.Parent = StarterPack
			end
		end

		for _, tool in StarterPack:GetChildren() do
			if not tool:IsA("Tool") then
				continue
			end

			local boostNameValue = tool:FindFirstChild("BoostName")
			if boostNameValue and boostNameValue:IsA("StringValue") then
				Util.Warn(
					`Boost item {tool.Name} uses a StringValue for BoostName, please change it to an attribute, as a StringValue can be manipulated (or even deleted) by the client.`
				)
				tool:SetAttribute("BoostName", boostNameValue.Value)
			end
		end

		EverpresentCOs.Parent = ServerStorage

		for _, towerFolder in TowerFolder:GetChildren() do
			Local.InitTower(towerFolder)
		end

		for _, portalPart in PortalFolder:GetChildren() do
			if portalPart:IsA("BasePart") then
				Local.InitPortal(portalPart)
			end
		end

		for _, marker in Markers:GetChildren() do
			if marker:IsA("BasePart") then
				Local.InitMarker(marker)
			end
		end
	end
end

function Local.InitTower(towerFolder: Folder): TowerInfo
	local acronym = towerFolder.Name
	local spawnLocation = towerFolder:FindFirstChild("SpawnLocation")
	assert(spawnLocation and spawnLocation:IsA("BasePart"), `{acronym} does not have a valid SpawnLocation!`)

	local clientObjects = towerFolder:FindFirstChild("ClientSidedObjects")
		or ClientObjectsFolder:FindFirstChild(acronym)
	local checkpointsFolder = towerFolder:FindFirstChild("Checkpoints")
		or TowerCheckpointsFolder:FindFirstChild(acronym)
	if checkpointsFolder and checkpointsFolder.Parent ~= TowerCheckpointsFolder then
		checkpointsFolder.Name = acronym
		checkpointsFolder.Parent = TowerCheckpointsFolder
		Util.Warn(
			`{acronym} is storing it's checkpoints in the workspace! consider moving the checkpoints folder to ServerStorage -> TowerCheckpoints`
		)
	end

	local checkpointsList = {}
	local checkpointCount = 0

	if checkpointsFolder then
		for i: number, _ in checkpointsFolder:GetChildren() do
			local checkpointName = tostring(i)
			local checkpoint: Instance = checkpointsFolder:FindFirstChild(checkpointName)
			if checkpoint then
				if checkpoint:IsA("BasePart") then
					table.insert(checkpointsList, checkpoint)
				else
					error(`{acronym}: Checkpoint {checkpointName} is not a BasePart.`)
				end
			else
				error(`{acronym}: Could not find checkpoint {checkpointName}.`)
			end
			checkpointCount += 1
		end
	end

	if checkpointCount == 0 and Configuration.CHECKPOINTS_MISSING_WARNING then
		Util.Warn(`{acronym} has no checkpoints!`)
	end

	local tower: TowerInfo = {
		Name = Util.GetString(towerFolder, "ProperName") or acronym,
		Difficulty = Util.GetString(towerFolder, "Difficulty") or "default",
		BadgeID = Util.GetInt(towerFolder, "BadgeID") or 0,
		Folder = towerFolder,
		SpawnLocation = spawnLocation,
		ClientObjects = clientObjects,
		Endings = {},
		MinimumTime = Util.GetNumber(towerFolder, "MinimumTime") or 0,
		Checkpoints = checkpointsList,
		CheckpointCount = checkpointCount,
	}

	if tower.ClientObjects then
		tower.ClientObjects.Name = acronym
		tower.ClientObjects.Parent = ClientObjectsFolder
	end

	if tower.MinimumTime == 0 and Configuration.NO_MINIMUM_TIME_WARNING then
		Util.Warn(`{acronym} has no mininum time, it is vulnerable to being cheesed!`)
	end

	Towers[acronym] = tower

	for _, v in TowerFolder:GetDescendants() do
		if v.Name == "Winpad" and v:IsA("BasePart") then
			Local.InitWinpad(acronym, v)
		end
	end

	return tower
end

function Local.InitWinpad(towerName: string, winpad: BasePart)
	local Particles = WinpadParticles:Clone()
	Particles.Parent = winpad

	local endingId = Util.GetString(winpad, "EndingID") or towerName
	winpad:SetAttribute("EndingID", endingId)

	if not Util.GetString(winpad, "ParentTower") then
		assert(towerName ~= "", `Could not setup winpad {winpad:GetFullName()} because its parent tower is undefined.`)
		winpad:SetAttribute("ParentTower", towerName)
	end

	local Tower: TowerInfo = Towers[towerName]
	assert(Tower, `Could not setup winpad {winpad:GetFullName()} because its parent tower does not exist.`)

	Tower.Endings[endingId] = {
		Name = Util.GetString(winpad, "EndingName") or Tower.Name,
		Difficulty = Util.GetString(winpad, "Difficulty") or Tower.Difficulty,
		BadgeID = Util.GetInt(winpad, "BadgeID") or 0,
		PreventTowerBadge = Util.GetBoolean(winpad, "PreventTowerBadge") or false,
		ParentTower = towerName,
		WinroomMarker = (Util.GetString(winpad, "WinroomMarker") or Util.GetString(winpad, "Winroom")),
	}

	Local.InitTouchHandler(winpad, { TowerName = towerName, EndingID = endingId })

	table.insert(Winpads, winpad)
end

function Local.InitPortal(portalPart: BasePart)
	local towerValue = portalPart:FindFirstChild("TowerPortal")
	local towerRushValue = portalPart:FindFirstChild("TowerRush")
	local legacyTowerRush = portalPart:FindFirstChild("TowerRushPortal")
	local lobbyTeleporter = portalPart:FindFirstChild("LobbyTeleporter")

	if towerValue and towerValue:IsA("StringValue") then
		Local.InitTouchHandler(portalPart, { TowerName = towerValue.Value, portal = { normal = true } })
	elseif towerRushValue and towerRushValue:IsA("StringValue") then
		Local.InitTouchHandler(
			portalPart,
			{ TowerName = towerRushValue.Value, portal = { towerRush = { towerRushName = towerRushValue } } }
		)
	elseif legacyTowerRush and legacyTowerRush:IsA("ModuleScript") then
		local towerRushName = Local.ConvertLegacyTowerRush(legacyTowerRush)

		Local.InitTouchHandler(portalPart, { portal = { towerRush = { towerRushName = towerRushName } } })
	elseif lobbyTeleporter and lobbyTeleporter:IsA("StringValue") then
		local targetPartName = lobbyTeleporter.Value
		local targetPart = Markers:FindFirstChild(targetPartName, true)

		if targetPart and targetPart:IsA("BasePart") then
			Local.InitTouchHandler(portalPart, { TowerName = towerRushValue.Value, portal = { normal = true } })
		else
			Util.Warn(
				`Could not setup teleporter "{portalPart:GetFullName()}" because it does not reference a BasePart.`
			)
		end
	else
		Util.Warn(`Part "{portalPart.Name}" was found in the portal folder but it isn't a portal. `)
	end
end

function Local.InitMarker(marker: BasePart)
	if marker.Name == "LobbyTP" then
		Local.InitTouchHandler(marker, { isMarker = true })
	end
end

function Local.InitTouchHandler(part: BasePart, touchOptions: TouchOptions)
	part.Touched:Connect(function(otherPart)
		Local.OnTouch(otherPart, touchOptions)
	end)
end

function Local.ConvertLegacyTowerRush(module: ModuleScript)
	local towerRushData = require(module) :: any
	local towerRush: TowerRush = {
		BadgeID = towerRushData.BadgeID,
		Title = towerRushData.ProperName,
		Difficulty = "unknown",
		WinroomMarker = "",
		Towers = {},
	}

	for i = 1, #towerRushData, 1 do
		local towerName = towerRushData[i]
		table.insert(towerRush.Towers, towerName)
	end

	LEGACY_TOWER_RUSHES += 1

	local towerRushName = `Unnamed {LEGACY_TOWER_RUSHES}`
	TowerRushes[towerRushName] = towerRush

	return towerRushName
end

function Local.CharacterAdded(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 and Configuration.R15_WARNING then
		Util.Warn(
			"Character spawned with R15 rig type, most obbying techniques are impossible. Ensure that the rig type is R6 in Game Settings."
		)
	end

	local player = Players[character.Name]
	if not player then
		return
	end

	Local.OnChildAdded(character, player)

	if player.IsLoadingTower then
		return
	end

	RemoteEvents.UnloadTower:FireClient(player.Player)
	Local.ResetPlayerInfo(player)
end

function Local.onPlayerAdded(player: Player)
	local info: PlayerInfo = {
		Player = player,
		GameTimer = 0,
		LastRestart = 0,
		CurrentTower = "",
		CurrentTowerCheckpoint = 0,
		BoostItemNames = {},
		BoostItemUsed = false,
		TowerTimer = 0,
		CurrentTowerRush = "",
		CurrentTowerRushIndex = 0,
		TouchEventBusy = false,
		IsLoadingTower = false,
		HasEverpresentCOs = false,
		DebugItemUsed = false,
	}
	Players[player.Name] = info

	if player.Character then
		Local.CharacterAdded(player.Character)
	end

	player.Team = Teams.Start
	player.CharacterAdded:Connect(Local.CharacterAdded)
end

function Local.onPlayerRemoving(player: Player)
	Players[player.Name] = nil
end

function Local.onStepped(time: number, deltaTime: number)
	for _, player in Players do
		player.GameTimer += deltaTime

		if player.CurrentTower ~= "" then
			local oldTowerTimer = player.TowerTimer
			player.TowerTimer += deltaTime

			local I = Configuration.TIMER_SYNC_INTERVAL
			local A = math.floor(oldTowerTimer / I) * I
			local B = math.floor(player.TowerTimer / I) * I

			if B > A then
				RemoteEvents.UpdateTowerTimer:FireClient(player.Player, player.TowerTimer)
			end

			local previousInterval = math.floor((time - deltaTime) / Configuration.CHECKPOINT_INTERVAL)
				* Configuration.CHECKPOINT_INTERVAL
			local currentInterval = math.floor(time / Configuration.CHECKPOINT_INTERVAL)
				* Configuration.CHECKPOINT_INTERVAL

			if previousInterval < currentInterval then
				local character = player.Player.Character

				if player.CurrentTower ~= "" and character then
					local tower = Towers[player.CurrentTower]
					local checkpoint = tower.Checkpoints[player.CurrentTowerCheckpoint]
					if checkpoint then
						local point = character:GetPivot().Position
						local touching = Util.IsPointInPart(point, checkpoint)
						if touching then
							player.CurrentTowerCheckpoint += 1
						end
					end
				end
			end
		end
	end

	do
		local previousInterval = math.floor((time - deltaTime) / Configuration.WINPAD_INTERVAL)
			* Configuration.WINPAD_INTERVAL
		local currentInterval = math.floor(time / Configuration.WINPAD_INTERVAL) * Configuration.WINPAD_INTERVAL
		if previousInterval < currentInterval then
			for _, instance: BasePart in Winpads do
				if Configuration.WINPADS_CHANGE_COLOR then
					instance.Color = Color3.fromHSV(math.random(0, 100) / 100, 1, 1)
				end

				if Configuration.WINPADS_CHANGE_MATERIAL then
					instance.Material = WinpadMaterials[math.random(1, #WinpadMaterials)]
				end
			end
		end
	end
end

--- @server
--- @within MultiTowerServer
--- Loads a tower by loading the COs, teleporting the player to the tower, and resetting their timer if needed
function Local.PlayerLoadTower(playerName: string, towerName: string, resetTimer: boolean)
	local player = Players[playerName]
	local tower = Towers[towerName]
	if not player then
		return
	end

	if not tower then
		Util.Warn(`Unknown tower {towerName}!`)
		return
	end

	if player.IsLoadingTower then
		return
	end

	if resetTimer then
		player.TowerTimer = 0
		player.BoostItemUsed = false
		player.BoostItemNames = {}
	end

	player.CurrentTower = towerName
	player.CurrentTowerCheckpoint = 1
	player.IsLoadingTower = true
	player.Player:LoadCharacter()

	repeat
		task.wait(0.05)
	until player.Player.Character

	local Character = player.Player.Character
	if Character then
		local ForceField = Character:FindFirstChildOfClass("ForceField")
		if ForceField then
			ForceField:Destroy()
		end

		Util.TeleportPlayerToPartWithWait(player.Player, tower.SpawnLocation)
	end

	local oldCOFolder = player.Player:FindFirstChild("ClientSidedObjects")
	if oldCOFolder then
		oldCOFolder:Destroy()
	end

	local purist = true
	if tower.ClientObjects then
		purist = false

		local COFolder = tower.ClientObjects:Clone()
		COFolder.Name = "ClientSidedObjects"
		COFolder.Parent = player.Player
	end

	RemoteEvents.LoadTower:FireClient(player.Player, towerName, purist, resetTimer)
	player.IsLoadingTower = false
end

function Local.PlayerLoadTowerRush(playerName: string, towerRushName: string)
	local player = Players[playerName]
	local towerRush: TowerRush = TowerRushes[towerRushName]
	if not (player and towerRush) or player.IsLoadingTower then
		return
	end

	player.CurrentTowerRush = towerRushName
	player.CurrentTowerRushIndex = 1
	player.BoostItemUsed = false
	player.BoostItemNames = {}

	local firstTower = towerRush.Towers[1]
	local towerCount = #towerRush.Towers

	Local.PlayerLoadTower(playerName, firstTower, true)
	RemoteEvents.UpdateTowerRush:FireClient(player.Player, 1, towerCount)
end

function Local.PlayerTouchedWinpad(playerName: string, towerName: string, endingId: string)
	local player = Players[playerName]
	local tower = Towers[towerName]
	if not (player and tower) or player.TouchEventBusy then
		return
	end

	player.TouchEventBusy = true

	local Ending: EndingInfo = tower.Endings[endingId]
	assert(Ending, `{playerName} touched a winpad in {towerName}, but the ending referenced does not exist.`)

	if player.CurrentTower == "" then
		player.TouchEventBusy = false
		return
	end

	if Ending.ParentTower ~= player.CurrentTower then
		Announcements.AntiCheatKick(player.Player, "Touched the winpad of a tower you're not in.")
		return
	end

	if not player.DebugItemUsed and tower.MinimumTime > 0 and player.TowerTimer < tower.MinimumTime then
		Announcements.AntiCheatKick(player.Player, "Completed the tower too early")
		return
	end

	if player.CurrentTowerRush == "" then
		local EndingDifficultyName = tower.Difficulty
		local EndingName = tower.Name
		local EndingWinroom = ""

		if endingId ~= towerName then
			EndingDifficultyName = Ending.Difficulty
			EndingName = Ending.Name
			EndingWinroom = Ending.WinroomMarker
		end

		Announcements.WinAnnouncement(player, EndingName, EndingDifficultyName)

		if tower.BadgeID ~= 0 and not Ending.PreventTowerBadge then
			BadgeService:AwardBadge(player.Player.UserId, tower.BadgeID)
		end

		if Ending.BadgeID ~= 0 then
			BadgeService:AwardBadge(player.Player.UserId, Ending.BadgeID)
		end

		Local.TeleportToWinroom(player, EndingWinroom)
	else
		Local.AdvanceTowerRush(playerName)
	end

	task.wait(0.01)
	player.TouchEventBusy = false
end

function Local.AdvanceTowerRush(playerName: string)
	local player = Players[playerName]
	if not player then
		return
	end

	local towerRush: TowerRush = TowerRushes[player.CurrentTowerRush]
	if not towerRush then
		return
	end

	local towerCount = #towerRush.Towers

	if player.CurrentTowerRushIndex == towerCount then
		Announcements.WinAnnouncement(player, towerRush.Title, towerRush.Difficulty)

		if towerRush.BadgeID ~= 0 then
			BadgeService:AwardBadge(player.Player.UserId, towerRush.BadgeID)
		end

		Local.TeleportToWinroom(player, towerRush.WinroomMarker)
	else
		player.CurrentTowerRushIndex += 1

		local towerName = towerRush.Towers[player.CurrentTowerRushIndex]

		Local.PlayerLoadTower(playerName, towerName, false)
		RemoteEvents.UpdateTowerRush:FireClient(player.Player, player.CurrentTowerRushIndex, towerCount)
	end
end

function Local.EverpresentCOsRequested(playerInstance: Player): (boolean, Folder?)
	local player = Players[playerInstance.Name]
	if not player or player.HasEverpresentCOs then
		return false, nil
	end

	local playerECOs: Folder = EverpresentCOs:Clone()
	playerECOs.Parent = playerInstance

	player.HasEverpresentCOs = true
	return true, playerECOs
end

function Local.PlayerRequestedRestart(playerInstance: Player)
	local player = Players[playerInstance.Name]

	if player.GameTimer - player.LastRestart < Configuration.RESTART_COOLDOWN or player.CurrentTower == "" then
		return
	end

	player.LastRestart = player.GameTimer

	if player.CurrentTowerRush == "" then
		Local.PlayerLoadTower(playerInstance.Name, player.CurrentTower, true)
	else
		Local.PlayerLoadTowerRush(playerInstance.Name, player.CurrentTowerRush)
	end
end

function Local.PlayerEquippedTool(player: PlayerInfo, item: Tool)
	local isDebugItem: boolean = item:GetAttribute("DebugItem") :: boolean
	local boostName: string = item:GetAttribute("BoostName") :: string
	local boostUsed = boostName and boostName ~= "" or false

	if isDebugItem or boostUsed then
		player.DebugItemUsed = true
	end

	if boostUsed then
		player.BoostItemUsed = true
		player.BoostItemNames[item.Name] = boostName or "Boost Item"
	end
end

function Local.ResetPlayerInfo(player: PlayerInfo)
	player.TowerTimer = 0
	player.CurrentTower = ""
	player.CurrentTowerCheckpoint = 0
	player.CurrentTowerRush = ""
	player.CurrentTowerRushIndex = 0
	player.BoostItemNames = {}
	player.BoostItemUsed = false
	player.DebugItemUsed = false
end

function Local.TeleportToWinroom(player: PlayerInfo, winroomMarker: string)
	player.TouchEventBusy = true
	player.Player.Team = Teams.Winners

	RemoteEvents.UnloadTower:FireClient(player.Player)
	Local.ResetPlayerInfo(player)

	local winroomPart = if winroomMarker ~= ""
		then Markers:FindFirstChild(winroomMarker, true)
		else Markers:FindFirstChild("WinroomSpawn", true)

	if winroomPart and winroomPart:IsA("BasePart") then
		Util.TeleportPlayerToPartWithWait(player.Player, winroomPart)
	end

	player.TouchEventBusy = false
end

function Local.OnTouch(otherPart: BasePart, options: TouchOptions)
	local isPlayer, playerName = Util.IsPlayerPart(otherPart)
	if not isPlayer then
		return
	end

	local player = Players[playerName]

	if options.isMarker then
		local spawnLocation = Markers:FindFirstChild("SpawnLocation")
		assert(
			spawnLocation and spawnLocation:IsA("BasePart"),
			"Could not initialize LobbyTP because a SpawnLocation couldn't be found."
		)

		player.Player.Team = Teams.Start
		Util.TeleportPlayerToPart(player.Player, spawnLocation)

		return
	end

	if options.portal then
		if options.portal.normal and options.TowerName then
			Local.PlayerLoadTower(playerName, options.TowerName, true)
		elseif options.portal.towerRush and options.portal.towerRush.towerRushName then
			Local.PlayerLoadTowerRush(playerName, options.portal.towerRush.towerRushName)
		elseif options.portal.lobbyTeleporter and options.portal.lobbyTeleporter.targetPart then
			player.TouchEventBusy = true
			Util.TeleportPlayerToPart(player.Player, options.portal.lobbyTeleporter.targetPart)
			player.TouchEventBusy = false
		end

		return
	end

	if
		options.TowerName
		and options.EndingID
		and not player.TouchEventBusy
		and Util.IsPlayerAlive(player.Player.Character)
	then
		Local.PlayerTouchedWinpad(playerName, options.TowerName, options.EndingID)
	end
end

function Local.OnChildAdded(object: Instance, player: PlayerInfo)
	object.ChildAdded:Connect(function(instance: Instance)
		if instance:IsA("Tool") then
			Local.PlayerEquippedTool(player, instance)
		end
	end)
end

return Shared
