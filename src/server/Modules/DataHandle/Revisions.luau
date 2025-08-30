--> Can also be a table path like ["Crew.Pirate.Name"]
local redactedData = {}

local replacedNames = {
	--["Old_Name"] = "New_Name"
}

return {
	IsRedacted = function(name: string, fullPath: string)
		return redactedData[name] or redactedData[fullPath]
	end,

	GetNewName = function(name: string, fullPath: string)
		return replacedNames[name] or replacedNames[fullPath] or name
	end,

	GetOldName = function(name)
		for oldName, newName in pairs(replacedNames) do
			if newName == name then
				return oldName
			end
		end

		return name
	end,
}
