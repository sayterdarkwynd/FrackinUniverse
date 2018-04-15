function init()
	--world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 5.0)
	script.setUpdateDelta(config.getParameter("scriptDelta"))
	status.addPersistentEffect("nooxygen", {stat = "breathRegenerationRate", effectiveMultiplier = 0})
end

function update(dt)
	status.setResource("breath", status.resource("breath") - (dt * status.stat("breathDepletionRate")))
end

function uninit()
	status.clearPersistentEffects("nooxygen")
end
