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
	bonusHandler=effect.addStatModifierGroup({})
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=((self.healingRate*math.max(0, 1 + status.stat("healingBonus") )) - self.penaltyRate)}})
	self.cooldown=math.max(15-self.duration,0)--base time is 15 seconds
	effect.modifyDuration(self.cooldown)
	self.timer=0.0
	self.timerSound = 0
end

function update(dt)
	if not self.timer then return end
	self.timer=self.timer + dt

	if self.timer >= self.duration then
		effect.setStatModifierGroup(bonusHandler,{})
		animator.setParticleEmitterActive("healing", false)
	else
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=((self.healingRate*math.max(0, 1 + status.stat("healingBonus") )) - self.penaltyRate)}})
		animator.setParticleEmitterActive("cantheal2", false)
		animator.setParticleEmitterOffsetRegion("cantheal", mcontroller.boundBox())
		animator.setParticleEmitterEmissionRate("cantheal", 0.5 )
		animator.setParticleEmitterActive("cantheal", true)
	end

	if effect.duration() <= 0.2 then
		animator.setParticleEmitterActive("cantheal", false)
		animator.setParticleEmitterOffsetRegion("cantheal2", mcontroller.boundBox())
		animator.setParticleEmitterEmissionRate("cantheal2", 3 )
		animator.setParticleEmitterActive("cantheal2", true)
		if self.timerSound == 0 then
			animator.playSound("ready",1)
			self.timerSound = self.timerSound + 1
		end
	end
end

function uninit()
	effect.modifyDuration(-self.cooldown)
	effect.removeStatModifierGroup(bonusHandler)
end
