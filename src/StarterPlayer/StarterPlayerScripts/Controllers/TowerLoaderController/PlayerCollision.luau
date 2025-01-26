local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local CollisionGroupThis = "Player"
local CollisionGroupOthers = "OtherPlayers"

local Local = {}
local Shared = {}

function Shared.OnStart()
	for _, player in Players:GetPlayers() do
		Local.onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(Local.onPlayerAdded)
	Player.CharacterAdded:Connect(Local.onCharacterAdded)
end

function AffectCharacter(character: Model, collisionGroup: string)
	for _, instance in character:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.CollisionGroup = collisionGroup
		end
	end

	character.DescendantAdded:Connect(function(instance)
		if instance:IsA("BasePart") then
			instance.CollisionGroup = collisionGroup
		end
	end)
end

function Local.onCharacterAdded(character: Model)
	local collisionGroup = if character == Player.Character then CollisionGroupThis else CollisionGroupOthers
	AffectCharacter(character, collisionGroup)
end

function Local.onPlayerAdded(player: Player)
	if player.Character then
		Local.onCharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(Local.onCharacterAdded)
end

return Shared
