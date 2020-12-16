function init()
	if (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) or (not world.entityExists(entity.id())) or ((world.entityType(entity.id())== "monster") and (world.callScriptedEntity(entity.id(),"getClass") == 'bee')) then
		effect.expire()
	end
	self.blinkTimer = 0
	if not blocker then blocker=config.getParameter("blocker","deathbombitem") end
end

function update(dt)
	self.blinkTimer = self.blinkTimer - dt
	if self.blinkTimer <= 0 then self.blinkTimer = 0.5 end

	if self.blinkTimer < 0.2 then
		effect.setParentDirectives(config.getParameter("flashDirectives", ""))
	else
		effect.setParentDirectives("")
	end

	if (status.resourcePercentage("health") <= 0.05) and status.resourceMax("health") >= config.getParameter("minMaxHealth", 0) then
		explode()
	end
end

function uninit()

end

function explode()
	if not blocker then blocker=config.getParameter("blocker","deathbombitem") end

	if not self.exploded and not status.statPositive("deathbombDud") and not status.statPositive(blocker) then
		local healthMultiplier=config.getParameter("healthMultiplier",1)
		local healthMax=status.resourceMax("health")
		local item=config.getParameter("item","money")
		local chance=config.getParameter("chance",100)

		if ((chance<100) and math.random(0,100)<chance) or (chance==100) then
			world.spawnItem(item, mcontroller.position(),math.max(1,math.floor(healthMax*healthMultiplier)))
		end
		status.addPersistentEffect(blocker,{stat=blocker,amount=1})
		self.exploded = true
		if status.isResource("stunned") then
			status.setResource("stunned",0)
		end
	end
end
