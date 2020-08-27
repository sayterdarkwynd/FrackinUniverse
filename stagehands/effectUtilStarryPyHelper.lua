require "/scripts/effectUtil.lua"

function init()
	self = config.getParameter("messageData")
end

function update(dt)
	if self and self.messageFunctionArgs and type(self.messenger) == "number" and world.entityExists(self.messenger) and world.entityType(self.messenger) == "player" then
		--sb.logInfo("EffectUtilHelper: %s applied: %s",world.entityName(self.messenger),self.messageFunctionArgs)
		effectUtil.effectTypesInRange(table.unpack(self.messageFunctionArgs))
	end
	stagehand.die()
end