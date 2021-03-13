function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	script.setUpdateDelta(5)
	self.tickTime = 3.0
	self.tickTimer = self.tickTime
	self.baseDamage = config.getParameter("healthDown",0)
	shrubbery=effect.addStatModifierGroup({
		{ stat = "physicalResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "radioactiveResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) }
	})
end

function update(dt)
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
	end
	if ( status.stat("poisonResistance") >= 0.25 ) then
			effect.expire()
	end
	effect.setParentDirectives("fade=806e4f=0.8")
end

function uninit()
	if shrubbery then
		effect.removeStatModifierGroup(shrubbery)
		shrubbery=nil
	end
end