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
do
	for _, v: Instance in RemotesFolder:GetChildren() do
		if v:IsA("RemoteEvent") then
			RemoteEvents[v.Name] = v
		elseif v:IsA("RemoteFunction") then
			RemoteFunctions[v.Name] = v
		end
	end
end

local LatestGlobalMessageID = ""

local Local = {}
local Shared = {}

function Shared.OnStart()
	MessagingService:SubscribeAsync("GlobalWin", Local.GlobalWinMessage)
end

function Local.BroadCastWinAnnouncement(Info: WinMessageInfo)
	local EndingDifficulty = Util:GetDifficulty(Info.DifficultyName)

	local ClientMessageInfo: ClientWinMessageInfo = {
		PlayerName = Info.PlayerName,
		EndingName = Info.EndingName,
		Time = Info.Time,
		BoostsUsed = Info.BoostsUsed,
		Color = EndingDifficulty.Color,
		FancyFont = EndingDifficulty.FancyFont,
	}
	RemoteEvents.GameWinAnnouncement:FireAllClients(ClientMessageInfo)
end

function Local.GlobalWinMessage(Message: Message)
	local Info: WinMessageInfo = Message.Data
	if Info.MessageID == LatestGlobalMessageID then
		return
	end

	Local.BroadCastWinAnnouncement(Info)
end

function Shared.GameAnnouncement(Message: string, Color: Color3, FancyText: boolean?)
	RemoteEvents.GameAnnouncement:FireAllClients(Message, Color, FancyText)
end

function Shared.AntiCheatKick(Player: Player, Reason: string)
	local Message: string = KickMessages[math.random(1, #KickMessages)]:gsub(
		"{Player}",
		if Configuration.USE_DISPLAY_NAME then Player.DisplayName else Player.Name
	)

	Shared.GameAnnouncement(Message, Color3.new(1, 0, 0))
	Player:Kick(Reason)
end

function Shared.WinAnnouncement(Player: PlayerInfo, EndingName: string, DifficultyName: string)
	local EndingDifficulty = Util:GetDifficulty(DifficultyName)

	local Info: WinMessageInfo = {
		MessageID = HttpService:GenerateGUID(false),
		PlayerName = if Configuration.USE_DISPLAY_NAME then Player.Player.DisplayName else Player.Player.Name,
		EndingName = EndingName,
		DifficultyName = DifficultyName,
		Time = Player.TowerTimer,
		BoostsUsed = Player.BoostItemNames,
	}

	if EndingDifficulty.GlobalAnnouncement then
		LatestGlobalMessageID = Info.MessageID
		MessagingService:PublishAsync("GlobalWin", Info)
	end

    Local.BroadCastWinAnnouncement(Info)
end

return Shared
