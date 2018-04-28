_init=init

function init()
	--sb.logInfo("\n%s\n%s",message,player)
	--if true then return end
	message.setHandler("player.uniqueId",player.uniqueId)
	message.setHandler("player.worldId",player.worldId)
	--sb.logInfo("FU Deployment hacks initialized!")
	_init()
end