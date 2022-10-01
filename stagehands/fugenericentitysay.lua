require "/scripts/util.lua"
require "/scripts/effectUtil.lua"

function init()
	self = config.getParameter("messageData")
end

function update(dt)
	if self and self.message and self.targetId and world.entityExists(self.targetId) then
		local eType=world.entityType(self.targetId)
		if (eType=="monster") or (eType=="npc") or ("object") then
			--local pass,result=
			pcall(world.callScriptedEntity,self.targetId, eType..".say",self.message)
		else
			effectUtil.messageParticle(world.entityPosition(self.targetId),self.message)
		end
	end
	stagehand.die()
end
