function init()
	if (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) or entity.entityType() ~="monster" then
		effect.expire()
	end
	self.blinkTimer = 0
end

function update(dt)
	self.blinkTimer = self.blinkTimer - dt
	if self.blinkTimer <= 0 then self.blinkTimer = 0.5 end

	if self.blinkTimer < 0.2 then
		effect.setParentDirectives(config.getParameter("flashDirectives", ""))
	else
		effect.setParentDirectives("")
	end

	if not status.resourcePositive("health") and status.resourceMax("health") >= config.getParameter("minMaxHealth", 0) then
		explode()
	end
end

function uninit()
  
end

function explode()
	if not self.exploded then
		for _=1,config.getParameter("count",1) do
			world.spawnMonster(world.monsterType(entity.id()),entity.position(),world.callScriptedEntity(entity.id(),"monster.uniqueParameters"))
		end
		self.exploded = true
	end
end
