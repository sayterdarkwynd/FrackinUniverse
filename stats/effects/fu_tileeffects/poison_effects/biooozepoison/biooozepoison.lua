function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	script.setUpdateDelta(20)
	self.tickTime = 2.0
	self.tickTimer = self.tickTime
	self.baseDamage = config.getParameter("healthDown",0)
	--self.baseTime = setEffectTime() --never actually used for anything.
	effect.addStatModifierGroup({
		{ stat = "physicalResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "fireResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "electricResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "iceResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "radioactiveResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "cosmicResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) }
	})
end

--see comment about self.baseTime
--[[function setEffectTime()
	return self.tickTimer * math.min(1 - status.stat("poisonResistance"), 0.45)
end]]

function update(dt)
	if ( status.stat("poisonResistance")	>= 0.4 ) then
		effect.expire()
	end

	self.tickTimer = self.tickTimer - dt

	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		if status.isResource("food") then
			status.setResource("food", status.resource("food") * 0.9905)
		end
	end

	effect.setParentDirectives("fade=CCFF33="..self.tickTimer * 0.4)
end

function uninit()

end
