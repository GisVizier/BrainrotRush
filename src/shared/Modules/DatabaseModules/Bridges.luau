local bridgeNet2 = require(game.ReplicatedStorage.Packages.BridgeNet2)

return {
	Server = bridgeNet2.ReferenceBridge("Server"),
	Client = bridgeNet2.ReferenceBridge("Client"),

	ClientUiHandle = bridgeNet2.ReferenceBridge("ClientUiHandle"),
	ServerFunction = bridgeNet2.ReferenceBridge("ServerFunction"),
}
