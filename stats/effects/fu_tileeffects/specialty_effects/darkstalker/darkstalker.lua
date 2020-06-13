function init()
	--self.maxHealth = status.stat("maxHealth")
	self.hasEnergy=status.isResource("energy")
	self.hasFood=status.isResource("food")
	self.maxDps = config.getParameter("maxDps")
	self.dps = 0
	self.tickDamagePercentage = 0.005
	self.tickTime = 0.1
	self.tickTimer = self.tickTime
	script.setUpdateDelta(1)
	activateVisualEffects()
	self.timers = {}

	local bounds = mcontroller.boundBox()
	setParticleConfig()
	script.setUpdateDelta(1)
	effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", baseMultiplier = 0.7 }})
end


function activateVisualEffects()
	if world.entityType(entity.id()) ~= "player" then
		effect.expire()
	end
	local statusTextRegion = { 0, 1, 0, 1 }
	animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
	animator.burstParticleEmitter("statustext")
	animator.playSound("burn")
	local lightLevel = getLight()
	  if lightLevel < 40 and world.entityType(entity.id()) == "player" then
	    --animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
	    --animator.setParticleEmitterActive("smoke", true)
		particleConfig.position=entity.position()
		world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
	  else
	    --animator.setParticleEmitterActive("smoke", false)
	  end  
end

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = world.lightLevel(position)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end


function setParticleConfig()
	particleConfig={type = "textured",image = "/animations/blur/blurshadow.png",velocity = {0, -2},approach = {15, 15},destructionAction = shrink,size = 1,layer = "front",variance = {initialVelocity = {1.0, 1.0}}}
	dt=script.updateDt()
	particleConfig.timeToLive = dt*15
	particleConfig.destructionTime = dt*15.0
end

function update(dt)
	if world.entityType(entity.id()) ~= "player" then
		effect.expire()
	end
	self.tickTimer = self.tickTimer - dt
	local lightLevel = getLight()

	local damageRatio = status.stat("maxHealth") / self.maxDps
	self.dps = (damageRatio * self.maxDps) /2

	self.dpsMod = 1 / lightLevel

	if lightLevel < 1 then
		self.dpsMod = 1.1
	end
	if lightLevel > 70 then
		--animator.setParticleEmitterActive("smoke", false)
		self.enabled=false
	end

	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		if lightLevel <=70 or (world.timeOfDay() > 0.5 or world.underground(mcontroller.position())) then
			if world.entityType(entity.id()) == "player" then
				---animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
				--animator.setParticleEmitterActive("smoke", true)
				self.enabled=true
			end
			status.modifyResource("health", (-self.dps * (self.dpsMod * 0.095) ) * dt)
			if self.hasEnergy then
				status.modifyResource("energy", (-self.dps * (self.dpsMod * 1.8) ) * dt)
			end
			if self.food then
				status.modifyResource("food", (-self.dps * (self.dpsMod * 0.009 ) ) * dt)
			end
		end
	end
	if self.enabled then
		particleConfig.position=entity.position()
		world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
	end
end


function uninit()

end
