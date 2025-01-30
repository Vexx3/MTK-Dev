local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configuration = require(ReplicatedStorage.Configs.Configuration)
local KickMessages = require(ReplicatedStorage.Configs.KickMessages)
local Types = require(ReplicatedStorage.Shared.Types)
local Util = require(ReplicatedStorage.Shared.Util)

type Dictionary<T> = Types.Dictionary<T>
type List<T> = Types.List<T>
type Difficulty = Types.DifficultyInfo
type PlayerInfo = Types.PlayerInfo
type Message = {
	Data: any,
	Sent: number,
}
type WinMessageInfo = {
	MessageID: string,
	PlayerName: string,
	EndingName: string,
	DifficultyName: string,
	Time: number,
	BoostsUsed: Dictionary<string>,
}
type ClientWinMessageInfo = {
	PlayerName: string,
	EndingName: string,
	Time: number,
	BoostsUsed: Dictionary<string>,
	Color: Color3,
}

local RemotesFolder = ReplicatedStorage.Remotes.TowerGame

local RemoteEvents: Dictionary<RemoteEvent> = {}
local RemoteFunctions: Dictionary<RemoteFunction> = {}

for _, v: Instance in RemotesFolder:GetChildren() do
	if v:IsA("RemoteEvent") then
		RemoteEvents[v.Name] = v
	elseif v:IsA("RemoteFunction") then
		RemoteFunctions[v.Name] = v
	end
end

local LatestGlobalMessageID = ""

local Local = {}
local Shared = {}

function Shared.OnStart()
	MessagingService:SubscribeAsync("GlobalWin", Local.GlobalWinMessage)
end

function Local:BroadCastWinAnnouncement(info: WinMessageInfo)
	local endingDifficulty = Util:GetDifficulty(info.DifficultyName)

	local clientMessageInfo: ClientWinMessageInfo = {
		PlayerName = info.PlayerName,
		EndingName = info.EndingName,
		Time = info.Time,
		BoostsUsed = info.BoostsUsed,
		Color = endingDifficulty.Color,
		FancyFont = endingDifficulty.FancyFont,
	}
	RemoteEvents.GameWinAnnouncement:FireAllClients(clientMessageInfo)
end

function Local:GlobalWinMessage(message: Message)
	local info: WinMessageInfo = message.Data
	if info.MessageID == LatestGlobalMessageID then
		return
	end

	Local:BroadCastWinAnnouncement(info)
end

function Shared:GameAnnouncement(message: string, color: Color3, fancyText: boolean?)
	RemoteEvents.GameAnnouncement:FireAllClients(message, color, fancyText)
end

function Shared:AntiCheatKick(player: Player, reason: string)
	local message: string = KickMessages[math.random(1, #KickMessages)]:gsub(
		"{Player}",
		if Configuration.USE_DISPLAY_NAME then player.DisplayName else player.Name
	)

	Shared:GameAnnouncement(message, Color3.new(1, 0, 0))
	player:Kick(reason)
end

function Shared:WinAnnouncement(player: PlayerInfo, endingName: string, difficultyName: string)
	local endingDifficulty = Util:GetDifficulty(difficultyName)

	local info: WinMessageInfo = {
		MessageID = HttpService:GenerateGUID(false),
		PlayerName = if Configuration.USE_DISPLAY_NAME then player.Player.DisplayName else player.Player.Name,
		EndingName = endingName,
		DifficultyName = difficultyName,
		Time = player.TowerTimer,
		BoostsUsed = player.BoostItemNames,
	}

	if endingDifficulty.GlobalAnnouncement then
		LatestGlobalMessageID = info.MessageID
		MessagingService:PublishAsync("GlobalWin", info)
	end

	Local:BroadCastWinAnnouncement(info)
end

return Shared
