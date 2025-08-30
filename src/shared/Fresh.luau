local players = game:GetService("Players")

local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")

local runService = game:GetService("RunService")
local guiService = game:GetService("GuiService")

local userInputService = game:GetService("UserInputService")
local collectionService = game:GetService("CollectionService")

local modulesFolder: Folder = replicatedStorage:WaitForChild("Modules")

local isClient: boolean, isServer: boolean = runService:IsClient(), runService:IsServer()

-- local Replion = require(modulesFolder:WaitForChild("Shared"):WaitForChild("Replion"))

type ModuleArray = { ModuleScript }
local module = {
	Disabled = false,
	ModulesLoaded = false,
	ClientModulesLoaded = false,
	ServerModulesLoaded = false,
	SharedModules = {},
	ClientModules = {},
	ServerModules = {},
	uiConnections = {},
	ActiveReplicas = {},
}

function module.SortModule(moduleA: ModuleScript, moduleB: ModuleScript)
	local priorityA = moduleA:GetAttribute("Priority") or 2
	local priorityB = moduleB:GetAttribute("Priority") or 2

	return priorityA < priorityB
end

function module.GetModuleDescendants(parent: Instance): ModuleArray
	if typeof(parent) ~= "Instance" then
		error(`Expected Instance as argument #1, got {typeof(parent)}`, 2)
	end

	local modules: ModuleArray = {}
	local stack: { Instance } = { parent }
	local current: Instance

	while #stack > 0 do
		current = table.remove(stack)
		local children = current:GetChildren()

		for _, child in children do
			if child:IsA("ModuleScript") then
				table.insert(modules, child)
			end

			if #child:GetChildren() > 0 then
				table.insert(stack, child)
			end
		end
	end

	return modules
end

local runTimeModules = runService:IsClient() and modulesFolder.Client:GetChildren()
	or runService:IsServer() and modulesFolder.Server:GetChildren()

local databaseModules = modulesFolder.DatabaseModules:GetDescendants()
local sharedModules = modulesFolder.Shared:GetChildren()

table.sort(databaseModules, module.SortModule)
table.sort(runTimeModules, module.SortModule)
table.sort(sharedModules, module.SortModule)

for i: number = 1, 3 do
	local index = if i == 1 then sharedModules elseif i == 2 then databaseModules else runTimeModules

	for _, moduleScript: ModuleScript? in index do
		if
			moduleScript:IsA("ModuleScript")
			and not (moduleScript.Parent:IsA("ModuleScript"))
			and not moduleScript:GetAttribute("Blacklist")
		then
			module.SharedModules[moduleScript.Name] = require(moduleScript) :: any
		end
	end
end

module.ModulesLoaded = true

function module.GetReplicaTable(): any
	return module.ActiveReplicas
end

function module.FillTable<Table>(subject, reference: { [any]: any }, overwrite: boolean? | false): Table
	if not (subject and subject ~= reference) then
		return subject
	end
	print(reference)
	for index, value in reference do
		local property = subject[index]
		local refProp = reference[index]

		print(property)
		print(refProp)
		if typeof(property) == "table" and typeof(refProp) == "table" then
			module.FillTable(property, refProp, overwrite)
		elseif overwrite or property == nil then
			subject[index] = value
		end
	end

	return subject
end

function module.getRandomIndex(tableIndex: any): any
	local count: number = #tableIndex
	if count == 0 then
		return nil
	end
	local index = math.random(1, count)
	return tableIndex[index]
end

function module.SelectOutcome(options)
	local totalWeight: number = 0
	for _, option in options do
		totalWeight = totalWeight + (option.probability or option.weight)
	end

	local threshold: number = math.random() * totalWeight
	local runningSum: number = 0

	for _, option in options do
		runningSum = runningSum + (option.probability or option.weight)
		if threshold <= runningSum then
			if type(option.color) == "function" then
				return option.color()
			elseif option.color then
				return option.color
			else
				return option.value
			end
		end
	end
end

function module.LoadCharacter(Player)
	if Player.Character then
		Player.Character:Destroy()
		Player.Character = nil
	end
	Player:LoadCharacter()
end

function module.SafePlayerRemoving(callback)
	for i, v in players:GetChildren() do
		callback(v)
	end
	return players.PlayerRemoving:Connect(callback)
end

function module.SafePlayerAdded(callback)
	for i, v in players:GetChildren() do
		callback(v)
	end
	return players.PlayerAdded:Connect(callback)
end

function module.SafeCharacterAdded(player: Player, callback: any): ()
	if player.Character then
		callback(player.Character)
	end

	return player.CharacterAdded:Connect(callback)
end

function module.SafeCharacterRemoving(player, callback)
	if player.Character then
		callback(player.Character)
	end

	return player.CharacterRemoving:Connect(callback)
end

local MAX_RETRIES: number = 16
function module.coreCall(method, ...)
	local result = {}
	for _ = 1, MAX_RETRIES do
		result = { pcall(starterGui[method], starterGui, ...) }
		if result[1] then
			break
		end
		runService.Stepped:Wait()
	end
	return unpack(result)
end

local function normalizePath(path: string | { string } | nil): { string }
	if not path then
		return {}
	end

	if typeof(path) == "string" then
		local parts = string.split(path, ".")
		local result = {}
		for _, part in parts do
			if part ~= "" then
				table.insert(result, part)
			end
		end
		return result
	end

	if typeof(path) == "table" then
		return path
	end

	return {}
end

function module.getNestedValue(tbl, path)
	local current = tbl
	for _, key in path do
		if type(current) ~= "table" then
			return nil
		end
		current = current[key]
	end
	return current
end

local Replica = if isClient
	then require(replicatedStorage.Modules.Client.ReplicaClient)
	else require(replicatedStorage.Modules.Server.ReplicaServer)

if isClient then
	local cn
	cn = Replica.OnNew("PlayerData", function(replica: ReplicaTypes.ClientReplica)
		cn:Disconnect()

		if replica:IsActive() then
			ClientReplica = replica

			local Maid = replica.Maid
			Maid:Add(function()
				ClientReplica = nil
			end)
		end
	end)

	Replica.OnNew("PeekableData", function(replica: ReplicaTypes.ClientReplica)
		local id = replica.Tags.UserId
		module.ActiveReplicas[id] = replica

		local Maid = replica.Maid
		Maid:Add(function()
			module.ActiveReplicas[id] = nil
		end)
	end)
end

local function IsPlrANpc(player: Player?)
	return players:FindFirstChild(player.Name)
end

local function fillPlayer(plr)
	return if isClient then players.LocalPlayer else plr
end

local function getData(plr, yield, raw)
	if isClient and typeof(plr) == "boolean" then
		yield = plr
	end

	plr = fillPlayer(plr)

	if not plr then
		return nil
	end

	if plr == players.LocalPlayer then
		if ClientReplica then
			return if raw then ClientReplica else ClientReplica.Data
		elseif yield then
			while task.wait() do
				if ClientReplica then
					return if raw then ClientReplica else ClientReplica.Data
				end
			end
		end
	end

	if IsPlrANpc(plr) then
		local Entity = plr
		local Holder = Entity.Parent

		local sMod = Holder:FindFirstChild("Stats")
		local Stats = sMod and require(sMod)

		if Stats then
			return Stats
		end
	else
		local id = plr.UserId
		local data = module.ActiveReplicas[id]

		if data then
			return if raw then data else data.Data
		elseif yield then
			while task.wait() do
				data = module.ActiveReplicas[id]

				if data then
					return if raw then data else data.Data
				end
			end
		end
	end

	return nil
end

function module.GetData(
	plr: Player,
	yield: boolean? | false,
	raw: boolean? | false
): (ReplicaTypes.ClientReplica | ReplicaTypes.ServerReplica)?
	return getData(plr, yield, raw)
end

local Alphabet: string = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
function addtoText(text: string): string
	local randomNumber: number = math.random(1, #Alphabet)
	local INDEX: number = math.random(1, 2)
	if INDEX == 2 then
		text = `{text}{(string.lower(string.sub(Alphabet, randomNumber, randomNumber)))}`
	else
		text = `{text}{(string.sub(Alphabet, randomNumber, randomNumber))}`
	end
	return text
end

function module.GenerateID(MAX: number): string
	MAX = MAX ~= nil and MAX or 5
	local text: string = ""
	text = addtoText(text)
	for _ = 1, MAX or 5 do
		if math.random(1, 2) == 1 then
			text = `{text}{tostring(math.random(1, 9))}`
		else
			text = addtoText(text)
		end
	end
	return text
end

function module:Alive(character: Model): boolean
	if
		character
		and character.PrimaryPart
		and character:FindFirstChild("Humanoid")
		and character.Humanoid:IsDescendantOf(workspace.World.Live)
		and character.Humanoid.Health > 0
		and character.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead
	then
		return true
	end
	return false
end

local required = {}

function module.SafeRequire(Module: ModuleScript, dontCheckTimeout: boolean?, Timeout: number?): (any, boolean)
	if required[Module] then
		return required[Module], true
	end
	local start: number = os.clock()
	local timeout: number = Timeout or 5
	local finishedOperation: boolean = false
	local returnModule: any

	if not dontCheckTimeout then
		task.spawn(function()
			while not finishedOperation do
				if os.clock() - start > timeout then
					warn(`{Module} module has taken too long to respond! {os.clock() - start} has elapsed.`)
					break
				end
				task.wait(0.5)
			end
		end)
	end

	local success: boolean, errorStatement: string = pcall(function()
		returnModule = require(Module)
	end)
	finishedOperation = true

	if not success then
		warn(errorStatement, Module)
	end

	if returnModule ~= nil then
		required[Module] = returnModule
		return returnModule, true
	else
		return nil, false
	end
end

function module.GetPlatform(): string
	if guiService:IsTenFootInterface() or userInputService.GamepadEnabled then
		return "Console"
	elseif
		(userInputService.TouchEnabled and not userInputService.MouseEnabled)
		or userInputService:GetLastInputType() == Enum.UserInputType.Touch
	then
		return "Mobile"
	else
		return "Desktop"
	end
end

function module.GetDeepCopy(Table): any
	local Copy = {}

	for Index, Value in pairs(Table) do
		local IndexType, ValueType = type(Index), type(Value)

		if IndexType == "table" and ValueType == "table" then
			Index, Value = module.GetDeepCopy(Index), module.GetDeepCopy(Value)
		elseif ValueType == "table" then
			Value = module.GetDeepCopy(Value)
		elseif IndexType == "table" then
			Index = module.GetDeepCopy(Index)
		end

		Copy[Index] = Value
	end

	return Copy
end

function module.NewInstance(ObjectInstance, Data, Duration)
	local NewInstance = Instance.new(ObjectInstance)
	if Data then
		for Property, Value in pairs(Data) do
			NewInstance[Property] = Value
		end
	end
	if Duration then
		task.delay(Duration, NewInstance.Destroy, NewInstance)
	end
	return NewInstance
end

local RNG = Random.new()
function module.RandomInteger(Min: number, Max: number): any
	return RNG:NextInteger(Min, Max)
end

return module
