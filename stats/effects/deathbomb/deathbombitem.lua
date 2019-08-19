function init()
	if status.resourceMax("health") < config.getParameter("minMaxHealth", 0) then
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
		local healthMultiplier=config.getParameter("healthMultiplier",1)
		local healthMax=status.resourceMax("health")
		local item=config.getParameter("item","money")
		local chance=config.getParameter("chance",100)
		
		if ((chance<100) and math.random(0,100)<chance) or (chance==100) then
			world.spawnItem(item, mcontroller.position(),math.max(1,math.floor(healthMax*healthMultiplier)))
		end
		self.exploded = true
	end
end
