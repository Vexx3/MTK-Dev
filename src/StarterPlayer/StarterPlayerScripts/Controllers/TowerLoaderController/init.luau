local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local ClientObjects = require(script.ClientObjects)
local Types = require(ReplicatedStorage.Shared.Types)
local GUI = require(script.GUI)

type Dictionary<T> = Types.Dictionary<T>

local RemotesFolder: Folder = ReplicatedStorage.Remotes.TowerGame

local Player = Players.LocalPlayer

local RemoteEvents: Dictionary<RemoteEvent> = {}
local RemoteFunctions: Dictionary<RemoteFunction> = {}
local ResetEffectGui: BindableEvent = RemotesFolder:WaitForChild("ResetEffectGui") :: BindableEvent

do
	for _, v: Instance in RemotesFolder:GetChildren() do
		if v:IsA("RemoteEvent") then
			RemoteEvents[v.Name] = v
		elseif v:IsA("RemoteFunction") then
			RemoteFunctions[v.Name] = v
		end
	end
end

local towerTimer = 0
local restartTime = 0
local RESTART_TIME_MAX = 5
local restartDebounce = false
local currentTower = ""

local Local = {}
local Shared = {}

function Shared.OnStart()
	RemoteEvents.UpdateTowerTimer.OnClientEvent:Connect(Local.CorrectTimer)
	RemoteEvents.UpdateTowerRush.OnClientEvent:Connect(Local.UpdateTowerRush)
	RemoteEvents.LoadTower.OnClientEvent:Connect(Local.LoadTower)
	RemoteEvents.UnloadTower.OnClientEvent:Connect(Local.UnloadTower)
	RunService.RenderStepped:Connect(Local.onStepped)

    do
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

        local ECOs: boolean, ECOFolder: Folder? = RemoteFunctions.RestartEverpresentCOs:InvokeServer()
        if ECOs and ECOFolder then
            ECOFolder.Parent = workspace
            ClientObjects.LoadClientObjects(ECOFolder, true)
        end

        Player.CharacterAdded:Connect(Local.onCharacterAdded)

        GUI:SetTowerTimer(0)
        GUI:SetTowerAcronym("")
        GUI:SetTowerRush(0, 0)
    end
end

function Local.LoadTower(acronym: string, purist: boolean, resetTimer: boolean)
	currentTower = acronym
	towerTimer = if resetTimer then 0 else towerTimer

	ResetEffectGui:Fire()

	restartTime = 0

	if restartTime >= RESTART_TIME_MAX then
		restartDebounce = true
	end

	if not purist then
		local COFolder = Player:WaitForChild("ClientSidedObjects", 10)
		assert(
			COFolder,
			"A tower has attempted to loaded in. It wasn't marked as purist but no ClientSidedObjects folder was sent over. Bad internet connection?"
		)

		ClientObjects.LoadClientObjects(COFolder, false)
	end
end

function Local.UnloadTower()
    currentTower = ""
    towerTimer = 0
    restartTime = 0
    
    ResetEffectGui:Fire()
    ClientObjects.UnloadClientObjects()

    GUI:SetTowerAcronym("")
    GUI:SetTowerTimer(0)
    GUI:SetTowerRush(0, 0)
    GUI:SetBoostsUsed(false)
    GUI:SetRestartLabel(0)
end

function Local.CorrectTimer(time: number)
    towerTimer = time
end

function Local.UpdateTowerRush(index: number, _end: number)
    GUI:SetTowerRush(index, _end)
end

function Local.onChildAdded(instance: Instance)
    instance.ChildAdded:Connect(function(inst: Instance)
        if inst:IsA("Tool") then
            local boostName: string? = inst:GetAttribute("BoostName") :: string

            if boostName and boostName ~= "" and currentTower ~= "" then
                GUI:SetBoostsUsed(true)
            end
        end
    end)
end

function Local.onCharacterAdded(character: Model)
    Local.onChildAdded(character)
end

function Local.onStepped(deltaTime: number)
    if currentTower == "" then
        towerTimer = 0
        restartTime = 0
    else
        towerTimer += deltaTime

        if UserInputService:IsKeyDown(Enum.KeyCode.R) then
            if not restartDebounce then
                restartTime = math.min(restartTime + deltaTime, RESTART_TIME_MAX)
                if restartTime >= RESTART_TIME_MAX then
                    restartDebounce = true
                    RemoteEvents.RestartRequested:FireServer()
                end
            end
        else
            restartTime = math.max(restartTime - deltaTime, 0)
            restartDebounce = false
        end
    end

    GUI:SetRestartLabel(restartTime / RESTART_TIME_MAX)
    GUI:SetTowerTimer(towerTimer)
end

return Shared
