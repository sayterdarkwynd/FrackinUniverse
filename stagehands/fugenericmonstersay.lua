require "/scripts/util.lua"

function init()
	self = config.getParameter("scanParams")
end

function update(dt)
	if self and self.message and self.monsterId then
		world.callScriptedEntity(self.monsterId, "monster.say",self.message)		
	end
	stagehand.die()
end