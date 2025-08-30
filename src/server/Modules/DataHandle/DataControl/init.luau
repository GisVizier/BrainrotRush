local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fresh = require(ReplicatedStorage.Fresh)
local ReplicaServer = require(ReplicatedStorage.Modules.Server.ReplicaServer)

local DefaultData = require(ReplicatedStorage.Modules.DatabaseModules.DefaultData)

local PeekableData = require(script.Parent.Peekable)
local Revisions = require(script.Parent.Revisions)
local ProfileStore = require(script:FindFirstChild("ProfileStore"))

local module = {}

local activeReplicas = Fresh.GetReplicaTable() :: { [number]: ReplicaServer.Replica }
local activeProfiles = {}

local STORE_VERSION: number = 1.8

local GameProfileStore = ProfileStore.New(`PlayerData{STORE_VERSION}`, DefaultData)
local Token = ReplicaServer.Token("PlayerData")
local PeekToken = ReplicaServer.Token("PeekableData")

function module.playerRemoval(player: Player)
	local playerData = activeReplicas[player.UserId]

	if playerData ~= nil then
		playerData:Destroy()
	end
end

local function updateKeys(Data, path: string)
	for key, value in Data do
		local pathKey = if path == "" then key else path .. "." .. key
		local redacted = Revisions.IsRedacted(key, pathKey)

		if redacted then
			Data[key] = nil
		else
			local newKey = Revisions.GetNewName(key, pathKey)
			if newKey ~= key then
				Data[newKey] = value
				Data[key] = nil
			end
			if type(value) == "table" then
				updateKeys(value, pathKey)
			end
		end
	end
end

function module:CompleteData<T>(Data: T): T
	updateKeys(Data, "")
	return Fresh.FillTable(Data, DefaultData)
end

local function GetPeekableData(Data: typeof(DefaultData)): {}
	local Peekable = {}

	for path in PeekableData do
		path = path:split(".")

		local referenceData = Data

		for _, key in path do
			referenceData = referenceData[key]
		end

		if referenceData and referenceData ~= Data then
			Peekable[path[1]] = referenceData
		end
	end

	return Peekable
end

function module.LoadPlayerData(player: Player): ReplicaServer.Replica | false
	local userId = player.UserId

	if activeReplicas[userId] then
		activeReplicas[userId]:Destroy()
		warn("Old data session found, Ending Profile Session for: " .. player.Name)
		-- return false
	end

	local playerProfile = GameProfileStore:StartSessionAsync("Player_" .. userId)

	if playerProfile then
		playerProfile:AddUserId(userId)

		if not player:IsDescendantOf(PlayerService) then
			playerProfile:EndSession()
		else
			local Data = ReplicaServer.New({
				Token = Token,
				Data = module:CompleteData(playerProfile.Data),
				Tags = { UserId = userId },
			})

			local Peekable = ReplicaServer.New({
				Token = PeekToken,
				Data = GetPeekableData(Data.Data),
				Tags = { UserId = userId },
			})

			activeProfiles[userId] = playerProfile
			activeReplicas[userId] = Data

			Data:SafeSubscribe(player)
			Peekable:Replicate()

			Data.Maid:Add(function()
				print(`Saved & Removed {player.Name}`)

				playerProfile:EndSession()
				Peekable:Destroy()

				activeProfiles[userId] = nil
				activeReplicas[userId] = nil
			end)

			print(`Data loaded for {player.Name}`)
			player:SetAttribute("Data_Loaded", true)
			return Data
		end
	else
		player:Kick("Data failed to load, Rejoin!")
	end

	return false
end

function module.GetReplica(player: Player | number): ReplicaServer.Replica?
	if typeof(player) == "number" then
		return activeReplicas[player]
	else
		return activeReplicas[player.UserId]
	end
end

function module.GetProfile(player: Player | number): ProfileStore.Profile<typeof(DefaultData)>?
	if typeof(player) == "number" then
		return activeProfiles[player]
	else
		return activeProfiles[player.UserId]
	end
end

Fresh.SafePlayerAdded(function(player: Player)
	module.LoadPlayerData(player)
end)

Fresh.SafePlayerRemoving(function(player: Player)
	module.playerRemoval(player)
end)

return module
