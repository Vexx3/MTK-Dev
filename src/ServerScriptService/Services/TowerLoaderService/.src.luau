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

function Local.InitTower(TowerFolder: Folder): TowerInfo
	local acronym = TowerFolder.Name
	local spawnLocation = TowerFolder:FindFirstChild("SpawnLocation")
	if not spawnLocation and spawnLocation:IsA("BasePart") then
		error(`{acronym} does not have a SpawnLocation!`)
	end

	local clientObjects = TowerFolder:FindFirstChild("ClientSidedObjects")
		or ClientObjectsFolder:FindFirstChild(acronym)
	local checkpointsFolder = TowerFolder:FindFirstChild("Checkpoints")
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
			local checkpoint = checkpointsFolder:FindFirstChild(checkpointName)
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
		Name = Util.GetString(TowerFolder, "ProperName") or acronym,
		Difficulty = Util.GetString(TowerFolder, "Difficulty") or "default",
		BadgeID = Util.GetInt(TowerFolder, "BadgeID") or 0,
		Folder = TowerFolder,
		SpawnLocation = spawnLocation,
		ClientObjects = clientObjects,
		Endings = {},
		MinimumTime = Util.GetNumber(TowerFolder, "MinimumTime") or 0,
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

function Local.InitWinpad(TowerName: string, Winpad: BasePart)
	local Particles = WinpadParticles:Clone()
	Particles.Parent = Winpad

	local EndingID = Util.GetString(Winpad, "EndingID") or ""
	if EndingID == "" then
		Winpad:SetAttribute("EndingID", TowerName)
		EndingID = TowerName
	end

	local ParentTower = Util.GetString(Winpad, "ParentTower") or ""
	if ParentTower == "" then
		if TowerName == "" then
			error(`Could not setup winpad {Winpad:GetFullName()} because it's parent tower is undefined.`)
		end
		Winpad:SetAttribute("ParentTower", TowerName)
	end

	local Tower: TowerInfo = Towers[TowerName]
	if Tower then
		local Ending: EndingInfo = {
			Name = Util.GetString(Winpad, "EndingName") or Tower.Name,
			Difficulty = Util.GetString(Winpad, "Difficulty") or Tower.Difficulty,
			BadgeID = Util.GetInt(Winpad, "BadgeID") or 0,
			PreventTowerBadge = Util.GetBoolean(Winpad, "PreventTowerBadge") or false,
			ParentTower = TowerName,
			WinroomMarker = (Util.GetString(Winpad, "WinroomMarker") or Util.GetString(Winpad, "Winroom")),
		}

		Tower.Endings[EndingID] = Ending

		Winpad.Touched:Connect(function(Hit)
			Local.OnTouch(Hit, TowerName, EndingID)
		end)
	else
		error(`Could not setup winpad {Winpad:GetFullName()} because it's parent tower does not exist.`)
	end

	table.insert(Winpads, Winpad)
end

function Local.PlayerLoadTower(PlayerName: string, TowerName: string, ResetTimer: boolean)
	local player = Players[PlayerName]
	local tower = Towers[TowerName]

	if player and tower then
		if player.IsLoadingTower then
			return
		end

		if ResetTimer then
			player.TowerTimer = 0
			player.BoostItemUsed = false
			player.BoostItemNames = {}
		end

		player.CurrentTower = TowerName
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
		RemoteEvents.LoadTower:FireClient(player.Player, TowerName, purist, ResetTimer)
		player.IsLoadingTower = false
	end

	if not tower then
		Util.Warn(`Unknown tower {TowerName}!`)
	end
end

function Local.PlayerTouchedWinpad(PlayerName: string, TowerName: string, EndingID: string)
	local player: PlayerInfo = Players[PlayerName]
	local tower: TowerInfo = Towers[TowerName]

	if player and tower then
		if player.TouchEventBusy then
			return
		end
		player.TouchEventBusy = true

		local Ending: EndingInfo = tower.Endings[EndingID]
		if Ending then
			if player.CurrentTower == "" then
				player.TouchEventBusy = false
				return
			end

			if Ending.ParentTower ~= player.CurrentTower then
				Announcements.AntiCheatKick(player.Player, "Touched the winpad of a tower you're not in.")
				return
			end

			if not player.DebugItemUsed then
				if tower.MinimumTime > 0 and player.TowerTimer < tower.MinimumTime then
					Announcements.AntiCheatKick(player.Player, "Completed the tower too early")
					return
				end
			end

			if player.CurrentTowerRush == "" then
				local EndingDifficultyName = tower.Difficulty
				local EndingName = tower.Name
				local EndingWinroom = ""

				if EndingID ~= TowerName then
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
				Local.AdvanceTowerRush(PlayerName)
			end
		else
			error(`{PlayerName} touched a winpad in {TowerName}, but the ending referenced does not exist.`)
		end

		task.wait(0.01)
		player.TouchEventBusy = false
	end
end

function Local.AdvanceTowerRush(PlayerName: string)
	local player = Players[PlayerName]
	if player then
		local towerRush: TowerRush = TowerRushes[player.CurrentTowerRush]
		if towerRush then
			local TowerCount = #towerRush.Towers

			if player.CurrentTowerRushIndex == TowerCount then
				Announcements.WinAnnouncement(player, towerRush.Title, towerRush.Difficulty)

				if towerRush.BadgeID ~= 0 then
					BadgeService:AwardBadge(player.Player.UserId, towerRush.BadgeID)
				end
				Local.TeleportToWinroom(player, towerRush.WinroomMarker)
			else
				player.CurrentTowerRushIndex += 1

				local towerName = towerRush.Towers[player.CurrentTowerRushIndex]
				Local.PlayerLoadTower(PlayerName, towerName, false)
				RemoteEvents.UpdateTowerRush:FireClient(player.Player, player.CurrentTowerRushIndex, TowerCount)
			end
		end
	end
end

function Local.ResetPlayerInfo(Player: PlayerInfo)
	Player.TowerTimer = 0
	Player.CurrentTower = ""
	Player.CurrentTowerCheckpoint = 0
	Player.CurrentTowerRush = ""
	Player.CurrentTowerRushIndex = 0
	Player.BoostItemNames = {}
	Player.BoostItemUsed = false
	Player.DebugItemUsed = false
end

function Local.TeleportToWinroom(Player: PlayerInfo, WinroomMarker: string)
	Player.TouchEventBusy = true
	Player.Player.Team = Teams.Winners

	RemoteEvents.UnloadTower:FireClient(Player.Player)
	Local.ResetPlayerInfo(Player)

	local winroomPart: Instance
	if WinroomMarker ~= "" then
		winroomPart = Markers:FindFirstChild(WinroomMarker, true)
	else
		winroomPart = Markers:FindFirstChild("WinroomSpawn", true)
	end

	if winroomPart and winroomPart:IsA("BasePart") then
		Util.TeleportPlayerToPartWithWait(Player.Player, winroomPart)
	end

	Player.TouchEventBusy = false
end

function Local.OnTouch(Hit: BasePart, TowerName: string, EndingID: string)
	local isPlayer, playerName = Util.IsPlayerPart(Hit)
	local player: PlayerInfo = Players[playerName]

	if isPlayer and not player.TouchEventBusy then
		if not Util.IsPlayerAlive(player.Player.Character) then
			return
		end
		Local.PlayerTouchedWinpad(playerName, TowerName, EndingID)
	end
end

return Shared
