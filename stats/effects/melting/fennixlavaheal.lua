function init()
	animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
	animator.setParticleEmitterActive("flames", true)
	effect.setParentDirectives("fade=FF8800=0.2")

	script.setUpdateDelta(10)
	healPerSecond=config.getParameter("healPerSecond",0)
	regenHandler=effect.addStatModifierGroup({})
	effect.setStatModifierGroup(regenHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*healPerSecond*math.max(0,1+status.stat("healingBonus"))}})
end

function update(dt)
	effect.setStatModifierGroup(regenHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*healPerSecond*math.max(0,1+status.stat("healingBonus"))}})
end

function uninit()
	effect.removeStatModifierGroup(regenHandler)
end