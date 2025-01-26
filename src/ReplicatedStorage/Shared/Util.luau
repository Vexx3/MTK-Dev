local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Difficulties = require(ReplicatedStorage.Configs.Difficulties)
local Types = require(ReplicatedStorage.Shared.Types)

type Dictionary<T> = Types.Dictionary<T>
type List<T> = Types.List<T>
type Difficulty = Types.DifficultyInfo

local warningTag = "[MTK]"

local Hip = CFrame.new(0, 3, 0)

local DefaultDifficulty: Difficulty = {
	Title = "Unknown",
	Rating = 0,
	Color = Color3.new(),
	FancyFont = false,
	GlobalAnnouncement = false,
}

local Shared = {}

function Shared:GetDifficulty(difficultyName: string)
	local Difficulty: Difficulty = Difficulties[difficultyName]
	return Difficulty or DefaultDifficulty
end

function Shared:IsPlayerPart(hit: BasePart)
	if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
		local Player = Players:GetPlayerFromCharacter(hit.Parent)
		if Player then
			return true, Player.Name
		end
	end

	return false, ""
end

function Shared:IsPlayerAlive(character: Model?)
	if not character then
		return false
	end

	local Humanoid = (character :: Model):FindFirstChildOfClass("Humanoid")
	if Humanoid then
		return Humanoid.Health > 0
	end

	return false
end

function Shared:IsPointInPart(point: Vector3, part: BasePart)
	local LocalPoint = part.CFrame:PointToObjectSpace(point)
	local UnitPoint = LocalPoint / part.Size

	return (
		UnitPoint.X <= 0.5
		and UnitPoint.X >= -0.5
		and UnitPoint.Y <= 0.5
		and UnitPoint.Y >= -0.5
		and UnitPoint.Z <= 0.5
		and UnitPoint.Z >= -0.5
	)
end

function Shared:FormatTimer(time: number)
	local milliseconds = string.format("%02d", math.floor((time % 1) * 100))
	local seconds = string.format("%02d", math.floor(time % 60))
	local minutes = string.format("%02d", math.floor(time / 60))

	return `{minutes}:{seconds}.{milliseconds}`
end

function Shared:Warn(message: string)
	warn(`{warningTag} {message}`)
end

-- Attributes
function Shared:GetNumber(instance: Instance, name: string)
	local Value = instance:FindFirstChild(name)
	if Value and Value:IsA("NumberValue") then
		return Value.Value
	end

	return instance:GetAttribute(name)
end

function Shared:GetInt(instance: Instance, name: string)
	local Value = instance:FindFirstChild(name)
	if Value and Value:IsA("IntValue") then
		return Value.Value
	end

	return instance:GetAttribute(name)
end

function Shared:GetString(instance: Instance, name: string)
	local Value = instance:FindFirstChild(name)
	if Value and Value:IsA("StringValue") then
		return Value.Value
	end

	return instance:GetAttribute(name)
end

function Shared:GetBoolean(instance: Instance, name: string)
	local Value = instance:FindFirstChild(name)
	if Value and Value:IsA("BoolValue") then
		return Value.Value
	end

	return instance:GetAttribute(name)
end

-- Teleportation
function Shared:TeleportPlayerToPartWithWait(player: Player, destination: BasePart)
	local Character = player.Character
	if Character then
		Character:PivotTo(destination.CFrame * Hip)
	else
		repeat
			task.wait(0.05)
			if player.Character then
				player.Character:PivotTo(destination.CFrame * Hip)
			end
		until player.Character
	end
end

function Shared:TeleportPlayerToPart(player: Player, destination: BasePart)
	local Character = player.Character
	if Character then
		Character:PivotTo(destination.CFrame * Hip)
	end
end

return Shared
