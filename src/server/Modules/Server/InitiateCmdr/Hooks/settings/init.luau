local settings = require(script.data)
local rankings = require(script.data.rankings)

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		if context.Group == "Admin" or context.Group == "Mod" or context.Group == "Owner" then
			local user_id = context.Executor.UserId

			local current_ranking = settings[context.Group][user_id]
				or settings["Owner"][user_id]
				or settings["Admin"][user_id]
				or settings["Mod"][user_id]
				or nil
			local number_rank = current_ranking ~= nil and rankings[current_ranking] or 0

			--print(number_rank,"players")
			--print(rankings[context.Group],"requirement")

			if number_rank < rankings[context.Group] then --or number_rank < rankings[context.Group] then
				return `this command is reserverd for {string.upper(context.Group)} only`
			end
		end
	end)
end
