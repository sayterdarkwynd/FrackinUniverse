local _init=init

function init()
	if _init then
		_init()
	end
	message.setHandler("player.uniqueId",player.uniqueId)
	message.setHandler("player.worldId",player.worldId)
	message.setHandler("player.availableTechs", player.availableTechs)
	message.setHandler("player.enabledTechs", player.enabledTechs)
	message.setHandler("player.shipUpgrades", player.shipUpgrades)
end