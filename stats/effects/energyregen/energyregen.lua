function init()
	animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
	animator.setParticleEmitterEmissionRate("energy", config.getParameter("emissionRate", 5))
	animator.setParticleEmitterActive("energy", true)

	handler=effect.addStatModifierGroup({
		{stat = "energyRegenPercentageRate", amount = config.getParameter("regenBonusAmount", 10)},
		{stat = "energyRegenBlockTime", effectiveMultiplier = 0.05}--vanilla: 0
	})
end

function uninit()
	effect.removeStatModifierGroup(handler)
	handler=nil
end
