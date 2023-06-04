function init()
	script.setUpdateDelta(3)
	self.baseValue = config.getParameter("baseValue",0)
	self.valBonus = config.getParameter("valBonus",0)

	self.timer = 10

	animator.setParticleEmitterOffsetRegion("insane", mcontroller.boundBox())
	animator.setParticleEmitterEmissionRate("insane", config.getParameter("emissionRate", 3))
	animator.setParticleEmitterActive("insane", true)
	activateVisualEffects()

	baseHandler=effect.addStatModifierGroup({{stat = "madnessModifier", amount = 1.25}})

	penaltyHandler=effect.addStatModifierGroup({})
	self.penaltyAmount=0.0
	self.penaltyRate=0.01 -- -1% shadow resistance per second
end


function update(dt)
	if world.getProperty("invinciblePlayers") or status.statPositive("invulnerable") or (entity.entityType() ~= "player") then
		return
	end

	self.timer = self.timer - dt
	if (self.timer <= 0) then
		self.healthDamage = ((math.max(1.0 - status.stat("mentalProtection"),0))*10) + status.stat("madnessModifier")
		self.timer = 30
		local afkLvl=afkLevel()
		if afkLvl > 3 then
			self.totalValue = 0
		else
			self.totalValue = self.baseValue + self.valBonus + math.random(1,6-afkLvl)
		end
		if (math.abs(mcontroller.xVelocity()) < 5) and (math.abs(mcontroller.yVelocity()) < 5) then
			if self.totalValue>0 then
				world.spawnItem("fumadnessresource",entity.position(),self.totalValue)
				animator.playSound("madness")
				activateVisualEffects()
			end
			status.applySelfDamageRequest({damageType = "IgnoresDef",damage = self.healthDamage,damageSourceKind = "shadow",sourceEntityId = entity.id()})
		end
	end

	self.penaltyTimer = (self.penaltyTimer or 0.0) + dt
	if self.penaltyTimer >= 1 then
		self.penaltyAmount=self.penaltyAmount-(self.penaltyRate*self.penaltyTimer)
		effect.setStatModifierGroup(penaltyHandler,{{stat = "shadowResistance", amount = self.penaltyAmount}})
		self.penaltyTimer=0.0
	end
end


function activateVisualEffects()
	effect.setParentDirectives("fade=765e72=0.4")
	if entity.entityType()=="player" then
		local statusTextRegion = { 0, 1, 0, 1 }
		animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
		animator.burstParticleEmitter("statustext")
	end
end

function uninit()
	effect.removeStatModifierGroup(penaltyHandler)
	effect.removeStatModifierGroup(baseHandler)
end

function afkLevel()
	return ((status.statusProperty("fu_afk_720s") and 4) or (status.statusProperty("fu_afk_360s") and 3) or (status.statusProperty("fu_afk_240s") and 2) or (status.statusProperty("fu_afk_120s") and 1) or 0)
end