function init()
	if (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) or (not world.entityExists(entity.id())) or ((world.entityType(entity.id())== "monster") and (world.callScriptedEntity(entity.id(),"getClass") == 'bee')) then
		effect.expire()
	end

	self.blinkTimer = 0
	if not blocker then blocker=config.getParameter("blocker","deathbombsimpleprojectile") end
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
	if not blocker then blocker=config.getParameter("blocker","deathbombsimpleprojectile") end
	if not self.exploded and not status.statPositive("deathbombDud") and not status.statPositive(blocker) then
		local projectileData=config.getParameter("projectile","invisibleprojectile")

		if type(projectileData)=="table" then
			projectileData=projectileData[math.floor(math.random(1,#projectileData))]
		end

		if type(projectileData)=="string" then
			world.spawnProjectile(projectileData, mcontroller.position(), 0, {0, 0}, false)
		end
		self.exploded = true
		status.addPersistentEffect(blocker,{stat=blocker,amount=1})
		if status.isResource("stunned") then
			status.setResource("stunned",0)
		end
	end
end
