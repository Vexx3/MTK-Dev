local HttpService = game:GetService("HttpService")

type COScriptContext = ModuleScript | StringValue

local ClientObjects: Instance?

local ThreadFolder: Folder = script.Parent.ClientObjectThreads
local ThreadTemplate = script.ClientObjectThread
local EverpresentClientObjectThreads = script.Parent.EverpresentClientObjectThreads
local ScriptRepo: Folder = script.Parent.ScriptRepo

local Shared = {}

function Shared.OnStart()
	do
		ThreadTemplate:WaitForChild("Repository").Value = ScriptRepo
	end
end

function Shared.LoadClientObjectScript(context: COScriptContext, orphaned: boolean)
	local thread = ThreadTemplate:Clone()
	thread.Name = HttpService:GenerateGUID(false)

	local threadContext = thread:WaitForChild("Context")
	threadContext.Value = context

	thread.Parent = if orphaned then EverpresentClientObjectThreads else ThreadFolder
	thread.Enabled = true
end

function Shared.LoadClientObjects(COFolder: Instance, orphaned: boolean)
	if not orphaned then
		Shared.UnloadClientObjects()
		ClientObjects = COFolder
	end

	COFolder.Name = "ClientObjects"
	COFolder.Parent = workspace

	for _, v: Instance in COFolder:GetChildren() do
		if
			v.Name == "ClientObjectScript" and v:IsA("ModuleScript")
			or v.Name == "RunRepoScript" and v:IsA("StringValue")
		then
			Shared.LoadClientObjectScript(v, orphaned)
		elseif v:IsA("StringValue") and v.Name == "SetCollisionGroup" and v.Parent and v.Parent:IsA("BasePart") then
			v.Parent.CollisionGroup = v.Value
		elseif (v.Name == "invisible" or v.Name == "LightingChanger") and v:IsA("BasePart") then
			v.Transparency = 1
		end
	end
end

function Shared.UnloadClientObjects()
	if ClientObjects then
		ClientObjects:Destroy()
	end

	ThreadFolder:ClearAllChildren()
end

return Shared
