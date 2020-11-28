require "/scripts/util.lua"

function init()
	self = config.getParameter("messageData")
end

function update(dt)
	if self and self.message and self.monsterId and world.entityExists(self.monsterId) then
		world.callScriptedEntity(self.monsterId, "monster.say",self.message)
	end
	stagehand.die()
end