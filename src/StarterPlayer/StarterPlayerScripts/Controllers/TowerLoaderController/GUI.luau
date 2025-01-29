local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Shared.Util)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local TowerGui: ScreenGui = PlayerGui:WaitForChild("TowerGUI")
TowerGui.Enabled = true

local TowerAcronym: TextLabel? = TowerGui:FindFirstChild("TowerAcronym", true) :: TextLabel
local TowerRushProgress: TextLabel? = TowerGui:FindFirstChild("TowerRushProgress", true) :: TextLabel
local Timer: TextLabel? = TowerGui:FindFirstChild("Timer", true) :: TextLabel
local BoostsUsed: TextLabel? = TowerGui:FindFirstChild("BoostsUsed", true) :: TextLabel
local RestartLabel: TextLabel? = TowerGui:FindFirstChild("RestartLabel", true) :: TextLabel

local RestartTransparency = 0
local RestartStrokeTransparency = 1

local Shared = {}

function Shared.OnStart()
	if RestartLabel then
		RestartTransparency = RestartLabel.TextTransparency
		RestartStrokeTransparency = RestartLabel.TextStrokeTransparency
	end
end

function Shared:SetTowerAcronym(acronym: string)
	if TowerAcronym then
		TowerAcronym.Text = acronym
		TowerAcronym.Visible = acronym ~= ""
	end
end

function Shared:SetTowerRush(progress: number, max: number)
	if TowerRushProgress then
		TowerRushProgress.Text = `{progress}/{max}`
		TowerRushProgress.Visible = max ~= 0
	end
end

function Shared:SetTowerTimer(time: number)
	if Timer then
		Timer.Text = Util:FormatTimer(time)
	end
end

function Shared:SetBoostsUsed(value: boolean)
	if BoostsUsed then
		BoostsUsed.Visible = value
	end
end

function Shared:SetRestartLabel(transparency: number)
	if RestartLabel then
		RestartLabel.Visible = transparency > 0
		RestartLabel.TextTransparency = 1 - (transparency * (1 - RestartTransparency))
		RestartLabel.TextStrokeTransparency = 1 - (transparency * (1 - RestartStrokeTransparency))
	end
end

return Shared
