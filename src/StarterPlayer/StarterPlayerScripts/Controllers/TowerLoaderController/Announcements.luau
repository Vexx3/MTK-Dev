local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Configuration = require(ReplicatedStorage.Configs.Configuration)
local Util = require(ReplicatedStorage.Shared.Util)
local Types = require(ReplicatedStorage.Shared.Types)

type ClientWinMessageInfo = Types.ClientWinMessageInfo
type Dictionary<T> = Types.Dictionary<T>

local RemotesFolder = ReplicatedStorage.Remotes.TowerGame
local GameAnnouncement = RemotesFolder.GameAnnouncement
local GameWinAnnouncement = RemotesFolder.GameWinAnnouncement

local Shared = {}

function Shared.OnStart()
	GameAnnouncement.OnClientEvent:Connect(function(...)
		Shared:DisplayMessage(...)
	end)

	GameWinAnnouncement.OnClientEvent:Connect(function(...)
		Shared:DisplayWinMessage(...)
	end)
end

function Shared:DisplayWinMessage(info: ClientWinMessageInfo)
	local boostsUsed = {}
	for _, boostName in info.BoostsUsed do
		table.insert(boostsUsed, boostName)
	end

	local boostList = if #boostsUsed > 0 then table.concat(boostsUsed, ", ") else ""

	local message = Configuration.WIN_MESSAGE
		:gsub("{PlayerName}", info.PlayerName)
		:gsub("{EndingName}", info.EndingName)
		:gsub("{Time}", "{Time:" .. tostring(info.Time) .. "}")
		:gsub("{BoostsUsed}", if #boostsUsed > 0 then `\n{Configuration.WIN_MESSAGE_BOOSTS_USED}` else "")
		:gsub("{BoostList}", boostList)

	Shared:DisplayMessage(message, info.Color, info.FancyFont)
end

function Shared:DisplayMessage(message: string, color: Color3, fancyText: boolean?)
	local timeMessage = Util:FormatTimeSyntax(message)

	if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
		Util:Warn(
			"TextChatService is currently using the deprecated LegacyChatService. The message will not be displayed. Please switch to the modern TextChatService for proper functionality."
		)
		return
	end

	local channels = TextChatService:FindFirstChild("TextChannels")
	assert(channels, "Message could not be displayed, could not find TextChannels folder")

	local TextChannel = channels:FindFirstChild(Configuration.CHAT_CHANNEL)
	assert(
		TextChannel and TextChannel:IsA("TextChannel"),
		"Could not find appropriate TextChannel, likely because either ChatChannel wasn't configured properly, or TextChatService.CreateDefaultTextChannels is disabled"
	)

	local colorString = `rgb({math.floor(color.R * 255)}, {math.floor(color.G * 255)}, {math.floor(color.B * 255)})`
	local faceString = if fancyText then Configuration.CHAT_FANCY_FONT_FACE else Configuration.CHAT_FONT_FACE
	local sizeString = if fancyText then Configuration.CHAT_FANCY_FONT_SIZE else Configuration.CHAT_FONT_SIZE

	local finalMessage = Configuration.CHAT_FONT
		:gsub("{FontColor}", colorString)
		:gsub("{FontFace}", faceString)
		:gsub("{FontSize}", sizeString)
		:gsub("{Message}", timeMessage)

	TextChannel:DisplaySystemMessage(finalMessage, "MTKSystem")
end

return Shared
