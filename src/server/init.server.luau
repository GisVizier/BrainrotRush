--!strict
local players = game:GetService("Players")

local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")

local runService = game:GetService("RunService")
local collectionService = game:GetService("CollectionService")

local fresh = require(replicatedStorage.Fresh)

local CACHED_MODULES = fresh.ServerModules

local CACHE_FOLDER = fresh.GetModuleDescendants(script)
table.sort(CACHE_FOLDER, fresh.SortModule)

local UNSUPPORTED: { string } = {}

local YIELD: boolean = false
local PRINT_UNSUPPORTED: boolean = false

local INTERVAL: number = 0

local LOAD_MODULES: { string } = { "InitiateCmdr", "AddRandomData" }

for _, module in CACHE_FOLDER :: { ModuleScript } do
	if module:IsA("ModuleScript") and not module:IsDescendantOf(script.Modules.Server.InitiateCmdr) then
		local moduleName: string = module.Name

		local moduleValue = fresh.SafeRequire(module)

		if type(moduleValue) == "function" and table.find(LOAD_MODULES, moduleName) then
			task.spawn(moduleValue, fresh)
			if YIELD then
				task.wait(INTERVAL)
			end
		elseif type(moduleValue) == "table" then
			moduleValue.Script = module

			if moduleValue.init then
				moduleValue.init(fresh)
			else
				CACHED_MODULES[moduleName] = moduleValue
			end
		else
			CACHED_MODULES[moduleName] = moduleValue
			table.insert(UNSUPPORTED, moduleName)
		end
	end
end

fresh.ModulesLoaded = true
fresh.ServerModulesLoaded = true

if #UNSUPPORTED > 0 and PRINT_UNSUPPORTED then
	warn(`Unsupported module types for modules: {table.concat(UNSUPPORTED, ", ")}`)
end

local function canClientCallModule(moduleName: string): boolean
	local module: ModuleScript? = CACHED_MODULES[moduleName]
	if typeof(module) == "table" and module.Script then
		return not module.Script:GetAttribute("CantClientCall")
	end

	return true
end

local bridges = fresh.SharedModules["Bridges"]

local function initiateModule(player: Player, data: any): any
	if data.Module and CACHED_MODULES[data.Module] then
		if not canClientCallModule(data.Module) then
			player:Kick(
				`{player.Name} tried exploiting modules that shouldn't be called from client, this will be logged`
			)
			return
		end
		return CACHED_MODULES[data.Module](fresh, player, data)
	end

	return "Failed pass"
end

bridges.Server:Connect(function(player: Player, Data: any)
	initiateModule(player, Data)
end)

local function onServerInvoke(player: Player, Data: any): any
	return initiateModule(player, Data)
end

bridges.ServerFunction.OnServerInvoke = onServerInvoke
