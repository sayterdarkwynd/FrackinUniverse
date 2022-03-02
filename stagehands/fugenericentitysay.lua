require "/scripts/util.lua"
require "/scripts/effectUtil.lua"

function init()
	self = config.getParameter("messageData")
	--sb.logInfo("%s",self)
end

function update(dt)
	if self and self.message and self.targetId and world.entityExists(self.targetId) then
		local eType=world.entityType(self.targetId)
		if eType=="monster" then
			world.callScriptedEntity(self.targetId, "monster.say",self.message)
		elseif eType=="npc" then
			world.callScriptedEntity(self.targetId, "npc.say",self.message)
		elseif eType=="object" then
			world.callScriptedEntity(self.targetId, "object.say",self.message)
		else
			effectUtil.messageParticle(world.entityPosition(self.targetId),self.message)
		end
	end
	stagehand.die()
end