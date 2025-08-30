--!strict
local players = game:GetService("Players")

local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")

local runService = game:GetService("RunService")
local collectionService = game:GetService("CollectionService")

local fresh = require(replicatedStorage.Fresh)
-- require(replicatedStorage:WaitForChild("CmdrClient"))

local CACHED_MODULES = fresh.ClientModules

local CACHE_FOLDER = fresh.GetModuleDescendants(script)
table.sort(CACHE_FOLDER, fresh.SortModule)

local UNSUPPORTED: { string } = {}

local YIELD: boolean = false
local PRINT_UNSUPPORTED: boolean = false

local INTERVAL: number = 0

local LOAD_MODULES: { string } = { "InitiateCmdr" }

for _, module in CACHE_FOLDER :: { ModuleScript } do
	if module:IsA("ModuleScript") then
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
fresh.ClientModulesLoaded = true

if #UNSUPPORTED > 0 and PRINT_UNSUPPORTED then
	warn(`Unsupported module types for modules: {table.concat(UNSUPPORTED, ", ")}`)
end

local bridges = fresh.SharedModules["Bridges"]

bridges.Client:Connect(function(data: any)
	if data.Module and CACHED_MODULES[data.Module] then
		CACHED_MODULES[data.Module](fresh, data)
	end
end)

warn("finished loading client")

print(fresh.ClientModules)
