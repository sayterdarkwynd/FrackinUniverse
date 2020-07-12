function init()
	if effect.duration()==0 then
		return
	end
	animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
	animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
	animator.setParticleEmitterActive("healing", true)

	script.setUpdateDelta(5)
	self.penaltyRate = config.getParameter("penaltyRate",0)
	self.duration=effect.duration()
	self.healingRate = config.getParameter("healAmount", 5) / self.duration
	self.healingBonus = status.stat("healingBonus") or 0
	self.healingRate = self.healingRate + self.healingBonus
	bonusHandler=effect.addStatModifierGroup({{stat="healthRegen",amount=(self.healingRate - self.penaltyRate)}})
	self.cooldown=math.max(20-self.duration,0)
	effect.modifyDuration(self.cooldown)
	self.timer=0.0
end

function update(dt)
	if not self.timer then return end
	self.timer=self.timer + dt
	if self.timer >= self.duration then
		effect.setStatModifierGroup(bonusHandler,{})
		animator.setParticleEmitterActive("healing", false)
	end
end

function uninit()
	effect.modifyDuration(-self.cooldown)
	effect.removeStatModifierGroup(bonusHandler)
end
