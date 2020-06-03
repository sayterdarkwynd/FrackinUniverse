function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	effect.setParentDirectives("fade=300030=0.8")
	baseHandler=effect.addStatModifierGroup({
		{stat = "jumpModifier", amount = -0.20}
	})
	bonusHandler=effect.addStatModifierGroup({})
	self.healingRate = 1
	script.setUpdateDelta(5)
end

function update(dt)

	if world.entitySpecies(entity.id()) == "glitch" then
		self.healingRate = 0.015
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})
		--status.modifyResourcePercentage("health", self.healingRate * dt)

		--sb.logInfo("tarslow")
		mcontroller.controlModifiers({
			groundMovementModifier = 1,
			speedModifier = 1,
			airJumpModifier = 1,
			liquidImpedance = 0.01
		})
	else
		mcontroller.controlModifiers({
			groundMovementModifier = 0.5,
			speedModifier = 0.65,
			airJumpModifier = 0.80
		})        
	end

end

function uninit()
	effect.removeStatModifierGroup(baseHandler)
	effect.removeStatModifierGroup(bonusHandler)
end
