function init()
	self.applyToTypes = {"player", "npc"}
	self.baseValue = config.getParameter("baseValue")
	self.valBonus = config.getParameter("valBonus") - ((config.getParameter("mentalProtection") or 0) * 10)
	self.timer = 10
	animator.setParticleEmitterOffsetRegion("insane", mcontroller.boundBox())
	animator.setParticleEmitterEmissionRate("insane", config.getParameter("emissionRate", 3))
	animator.setParticleEmitterActive("insane", true)
	activateVisualEffects()

	effect.addStatModifierGroup({{stat = "madnessModifier", amount = status.stat("madnessModifier") * 1.25}})

	script.setUpdateDelta(3)
end

function allowedType()
	local entityType = entity.entityType()
	for _,applyType in ipairs(self.applyToTypes) do
		if entityType == applyType then
			return true
		end
	end
end

function update(dt)
	if world.getProperty("invinciblePlayers") or status.statPositive("invulnerable") or (entity.entityType() ~= "player") then
		return
	end
	self.timer = self.timer - dt
	if (self.timer <= 0) then
		if not status.statusProperty("fu_afk_30s") then
			self.healthDamage = ((math.max(1.0 - status.stat("mentalProtection"),0))*10) + status.stat("madnessModifier")
			self.timer = 30
			self.totalValue = self.baseValue + self.valBonus + math.random(1,6)
			if (math.abs(mcontroller.xVelocity()) < 5) and (math.abs(mcontroller.yVelocity()) < 5) then
				world.spawnItem("fumadnessresource",entity.position(),self.totalValue)
				animator.playSound("madness")
				activateVisualEffects()
				status.applySelfDamageRequest({damageType = "IgnoresDef",damage = self.healthDamage,damageSourceKind = "shadow",sourceEntityId = entity.id()})
			end
		end
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
