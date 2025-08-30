local replicatedStorage = game:GetService("ReplicatedStorage")

local packages = replicatedStorage.Packages
local cmdr = require(packages.cmdr)

local module = {}

function module.init()
	cmdr:RegisterDefaultCommands() -- START UP
	cmdr:RegisterHooksIn(script.Hooks)
end

return module
