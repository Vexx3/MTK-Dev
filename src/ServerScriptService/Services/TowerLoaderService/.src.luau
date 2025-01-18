local BadgeService = game:GetService("BadgeService")
local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local Teams = game:GetService("Teams")

local Configs = ReplicatedStorage.Configs
local TowerLoaderService = script.Parent.TowerLoaderService
local Announcements = require(TowerLoaderService.Announcements)
local Configuration = require(Configs.Configuration)
local Types = require(TowerLoaderService.Types)
local Util = require(TowerLoaderService.Util)
local TowerRushes = require(Configs.TowerRushes)

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

local TowersFolder = workspace.Towers
local PortalsFolder = workspace.Portals
local Markers = workspace.Markers
local RemotesFolder = ReplicatedStorage.Remotes.TowerGame
local ClientObjectsFolder = ReplicatedStorage.TowerClientObjects
local TowerCheckpointsFolder = ServerStorage.TowerCheckpoints
local WinpadParticles: ParticleEmitter = ServerStorage.WinpadParticles
local EverpresentCOs = TowersFolder:WaitForChild("EverpresentCOs")

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

local Local = {}
local Shared = {}

function Shared.OnStart()
	-- later
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

	for _, v in TowersFolder:GetDescendants() do
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

function Local.InitTouchHandler(part: BasePart, touchOptions: TouchOptions)
	part.Touched:Connect(function(otherPart)
		Local.OnTouch(otherPart, touchOptions)
	end)
end

function Local.PlayerLoadTower(playerName: string, towerName: string, resetTimer: boolean)
	local player = Players[playerName]
	local tower = Towers[towerName]

	if player and tower then
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
		player.player:LoadCharacter()

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

	if not tower then
		Util.Warn(`Unknown tower {towerName}!`)
	end
end

function Local.PlayerLoadTowerRush(playerName: string, towerRushName: string)
	local player = Players[playerName]
	local towerRush: TowerRush = TowerRushes[towerRushName]

	if player and towerRush then
		if player.IsLoadingTower then
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
end

function Local.PlayerTouchedWinpad(playerName: string, towerName: string, endingId: string)
	local player: PlayerInfo = Players[playerName]
	local tower: TowerInfo = Towers[towerName]

	if player and tower then
		if player.TouchEventBusy then
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
end

function Local.AdvanceTowerRush(playerName: string)
	local player = Players[playerName]
	if player then
		local towerRush: TowerRush = TowerRushes[player.CurrentTowerRush]
		if towerRush then
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

	local winroomPart: Instance
	if winroomMarker ~= "" then
		winroomPart = Markers:FindFirstChild(winroomMarker, true)
	else
		winroomPart = Markers:FindFirstChild("WinroomSpawn", true)
	end

	if winroomPart and winroomPart:IsA("BasePart") then
		Util.TeleportPlayerToPartWithWait(player.Player, winroomPart)
	end

	player.TouchEventBusy = false
end

function Local.ConvertLegacyTowerRush(module: ModuleScript)
	local towerRushData = require(module)
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

function Local.OnTouch(otherPart: BasePart, options: TouchOptions)
	local isPlayer, playerName = Util.IsPlayerPart(otherPart)
	if not isPlayer then
		return
	end

	local player: PlayerInfo = Players[playerName]

	if options.isMarker then
		local spawnLocation: Instance = Markers:FindFirstChild("SpawnLocation")
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

return Shared
