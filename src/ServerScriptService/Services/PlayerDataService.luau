local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Configuration = require(ReplicatedStorage.Configs.Configuration)
local UpdateState = require(ReplicatedStorage.Functions.UpdateState)
local ProfileStore = require(ServerScriptService.Packages.ProfileStore)

local Remotes = ReplicatedStorage.Remotes.PlayerData

export type StateAction = UpdateState.StateAction

local PlayerDataTemplate = Configuration.DEFAULT_PLAYER_DATA
local DATA_STORE_KEY = Configuration.DATA_STORE_KEY
if RunService:IsStudio() then
	DATA_STORE_KEY = "Test"
end

local PlayerStore = ProfileStore.New(DATA_STORE_KEY, PlayerDataTemplate)
local Profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.Start.OnServerEvent:Connect(function(player: Player)
		local state = Shared:GetData(player)
		if state then
			Remotes.SetState:FireClient(player, state)
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(Local.LoadProfile, player)
	end

	Players.PlayerAdded:Connect(Local.LoadProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)
end

function Shared:UpdateState(player: Player, action: StateAction)
	local profile = Profiles[player]
	if not profile then
		return
	end

	UpdateState(profile.Data, action)
	Remotes.UpdateState:FireClient(player, action)

	if action.action == "UpdateTowers" then
		Shared.UpdateTowers(player, action.towerCount)
	end
end

function Local:CreateLeaderstats(player: Player)
	local data = Shared:GetData(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local towers = Instance.new("NumberValue")
	towers.Name = Configuration.TOWER_STAT_NAME
	towers.Value = data.towers
	towers.Parent = leaderstats

	local gameTime = Instance.new("NumberValue")
	gameTime.Name = "Time"
	gameTime.Parent = leaderstats
end

function Local.LoadProfile(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		return player:Kick("Profile load fail. Please rejoin.")
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Profile session ended. Please rejoin.")
	end)

	local isInGame = player.Parent == Players
	if isInGame then
		Profiles[player] = profile
	else
		profile:EndSession()
	end

	Local:CreateLeaderstats(player)
	Remotes.SetState:FireClient(player, profile.Data)

	return nil
end

function Local:RemoveProfile(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

function Shared:GetData(player: Player): Configuration.PlayerData?
	local profile = Profiles[player]
	if not profile then
		return
	end

	return profile.Data
end

function Shared.UpdateTowers(player: Player, towerCount: number)
	local data = Shared:GetData(player)
	if not data then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	leaderstats[Configuration.TOWER_STAT_NAME].Value = towerCount
end

return Shared
