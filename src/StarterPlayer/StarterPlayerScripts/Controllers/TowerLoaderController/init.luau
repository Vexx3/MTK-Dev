local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local ClientObjects = require(script.ClientObjects)
local Types = require(ReplicatedStorage.Shared.Types)

type Dictionary<T> = Types.Dictionary<T>

local RemotesFolder: Folder = ReplicatedStorage.Remotes.TowerGame

local Player = Players.LocalPlayer

local RemoteEvents: Dictionary<RemoteEvent> = {}
local RemoteFunctions: Dictionary<RemoteFunction> = {}
local ResetEffectGui: BindableEvent = RemotesFolder:WaitForChild("ResetEffectGui") :: BindableEvent

local TOWER_TIMER = 0
local RESTART_TIME = 0
local RESTART_TIME_MAX = 5
local RESTART_DEBOUNCE = false
local CURRENT_TOWER = ""

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

        -- TODO: Add GUI
    end
end

function Local.LoadTower(acronym: string, purist: boolean, resetTimer: boolean)
	CURRENT_TOWER = acronym
	TOWER_TIMER = if resetTimer then 0 else TOWER_TIMER

	ResetEffectGui:Fire()

	RESTART_TIME = 0

	if RESTART_TIME >= RESTART_TIME_MAX then
		RESTART_DEBOUNCE = true
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
    CURRENT_TOWER = ""
    TOWER_TIMER = 0
    RESTART_TIME = 0
    
    ResetEffectGui:Fire()
    ClientObjects.UnloadClientObjects()

    -- TODO: Add GUI
end

function Local.CorrectTimer(time: number)
    TOWER_TIMER = time
end

function Local.UpdateTowerRush(index: number, _end: number)
    -- TODO: Add GUI
end

function Local.onChildAdded(instance: Instance)
    instance.ChildAdded:Connect(function(inst: Instance)
        if inst:IsA("Tool") then
            local boostName: string? = inst:GetAttribute("BoostName")

            if boostName and boostName ~= "" and CURRENT_TOWER ~= "" then
                -- TODO: Add GUI
            end
        end
    end)
end

function Local.onCharacterAdded(character: Model)
    Local.onChildAdded(character)
end

function Local.onStepped(deltaTime: number)
    if CURRENT_TOWER == "" then
        TOWER_TIMER = 0
        RESTART_TIME = 0
    else
        TOWER_TIMER += deltaTime

        local previousRestartTime = deltaTime

        if UserInputService:IsKeyDown(Enum.KeyCode.R) then
            if not RESTART_DEBOUNCE then
                RESTART_TIME = math.min(RESTART_TIME + deltaTime, RESTART_TIME_MAX)
                if RESTART_TIME >= RESTART_TIME_MAX then
                    RESTART_DEBOUNCE = true
                    RemoteEvents.RestartRequested:FireServer()
                end
            end
        else
            RESTART_TIME = math.max(RESTART_TIME - deltaTime, 0)
            RESTART_DEBOUNCE = false
        end
    end

    -- TODO: Add GUI
end

return Shared
