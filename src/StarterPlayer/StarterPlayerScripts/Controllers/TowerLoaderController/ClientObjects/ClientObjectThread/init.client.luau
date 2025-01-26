local Repository: ObjectValue = script.Repository.Value
local Context: ObjectValue = script.Context.Value

local Body: ModuleScript

if Context:IsA("StringValue") then
	local repoScript: Instance? = Repository:FindFirstChild(Context.Value)

	if repoScript and repoScript:IsA("ModuleScript") then
		Body = repoScript:Clone()
		Body.Name = `RepoScriptInstantiation_{Body.Name}`
		Body.Parent = Context.Parent
	end
elseif Context:IsA("ModuleScript") then
	Body = Context
end

task.spawn(require(Body))
