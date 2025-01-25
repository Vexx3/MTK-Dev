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

-- Attributes
function Shared.GetNumber(Ins: Instance, Name: string)
	local Value = Ins:FindFirstChild(Name)
	if Value and Value:IsA("NumberValue") then
		return Value.Value
	end

	return Ins:GetAttribute(Name) :: number
end

function Shared.GetInt(Ins: Instance, Name: string)
	local Val = Ins:FindFirstChild(Name)
	if Val and Val:IsA("IntValue") then
		return Val.Value
	end

	return Ins:GetAttribute(Name) :: number
end

function Shared.GetString(Ins: Instance, Name: string)
	local Val = Ins:FindFirstChild(Name)
	if Val and Val:IsA("StringValue") then
		return Val.Value
	end

	return Ins:GetAttribute(Name) :: string
end

function Shared.GetBoolean(Ins: Instance, Name: string)
	local Val = Ins:FindFirstChild(Name)
	if Val and Val:IsA("BoolValue") then
		return Val.Value
	end

	return Ins:GetAttribute(Name) :: boolean
end

function Shared.IsPlayerPart(Hit: BasePart)
	if Hit.Parent and Hit.Parent:FindFirstChild("Humanoid") then
		local Player: Player = Players:GetPlayerFromCharacter(Hit.Parent)
		if Player then
			return true, Player.Name
		end
	end

	return false, ""
end

function Shared.IsPlayerAlive(Character: Model?)
	if not Character then
		return false
	end

	local Humanoid = (Character :: Model):FindFirstChildOfClass("Humanoid")
	if Humanoid then
		return Humanoid.Health > 0
	end

	return false
end

function Shared.IsPointInPart(Point: Vector3, Part: BasePart)
	local LocalPoint = Part.CFrame:PointToObjectSpace(Point)
	local UnitPoint = LocalPoint / Part.Size

	return (
		UnitPoint.X <= 0.5
		and UnitPoint.X >= -0.5
		and UnitPoint.Y <= 0.5
		and UnitPoint.Y >= -0.5
		and UnitPoint.Z <= 0.5
		and UnitPoint.Z >= -0.5
	)
end

function Shared.GetDifficulty(DifficultyName: string)
	local Difficulty: Difficulty = Difficulties[DifficultyName]
	return Difficulty or DefaultDifficulty
end

-- Teleportation
function Shared.TeleportPlayerToPartWithWait(Player: Player, Destination: BasePart)
	local Character = Player.Character
	if Character then
		Character:PivotTo(Destination.CFrame * Hip)
	else
		repeat
			task.wait(0.05)
			if Player.Character then
				Player.Character:PivotTo(Destination.CFrame * Hip)
			end
		until Player.Character
	end
end

function Shared.TeleportPlayerToPart(Player: Player, Destination: BasePart)
	local Character = Player.Character
	if Character then
		Character:PivotTo(Destination.CFrame * Hip)
	end
end

function Shared.Warn(Message: string)
	warn(`{warningTag} {Message}`)
end

return Shared
