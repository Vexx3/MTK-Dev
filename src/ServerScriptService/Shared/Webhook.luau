type WebhookType = "Normal" | "SC" | "Kick"

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configuration = require(ReplicatedStorage.Configs.Configuration)
local Types = require(ReplicatedStorage.Shared.Types)
local Util = require(ReplicatedStorage.Shared.Util)

type EndingInfo = Types.EndingInfo
type PlayerInfo = Types.PlayerInfo

local Local = {}
local Shared = {}

-- Safely get the secret in the game without causing an error if it's not found
function Local:GetSecret(key: string)
	local success, result = pcall(function()
		return HttpService:GetSecret(key)
	end)

	return if success then result else nil
end

local WEBHOOKS = {
	Normal = Local:GetSecret("tower_webhook"),
	SC = Local:GetSecret("sc_webhook"),
	Kick = Local:GetSecret("kick_webhook"),
}

function Shared:SendMessage(player: PlayerInfo, ending: EndingInfo)
	local endingDifficulty = Util:GetDifficulty(ending.Difficulty)
	local timeMessage = Util:FormatTimeSyntax("{Time:" .. tostring(player.TowerTimer) .. "}")

	local webhookUrl

	if endingDifficulty.Rating >= Configuration.SC_RATING then
		webhookUrl = WEBHOOKS.SC
	else
		webhookUrl = WEBHOOKS.Normal
	end

	local boostsUsed = {}
	for _, boostName in player.BoostItemNames do
		table.insert(boostsUsed, boostName)
	end

	local boostList = if #boostsUsed > 0 then table.concat(boostsUsed, ", ") else ""

	local message = Configuration.WEBHOOK_MESSAGE
		:gsub("{PlayerName}", if Configuration.USE_DISPLAY_NAME then player.Player.DisplayName else player.Player.Name)
		:gsub("{EndingName}", ending.Name)
		:gsub("{EndingEmoji}", endingDifficulty.Emoji)
		:gsub("{Time}", timeMessage)

	local boostMessage = if #boostList > 0 then `\nUsed: {boostList}` else ""
	message = message .. boostMessage

	local payload = {
		content = message,
	}

	local JSONPayload = HttpService:JSONEncode(payload)

	local success, response = pcall(function()
		return HttpService:PostAsync(webhookUrl, JSONPayload)
	end)

	if not success then
		Util:Warn(`Failed to send message to Discord: ${response}!`)
	end
end

return Shared
