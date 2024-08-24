require "/stats/effects/fu_statusUtil.lua"

function init()
	animator.setParticleEmitterOffsetRegion("dripshealing", mcontroller.boundBox())
	if (mcontroller.liquidPercentage() < 0.30) then
		animator.setParticleEmitterActive("dripshealing", true)
	else
		animator.setParticleEmitterActive("dripshealing", false)
	end

	effect.setParentDirectives("fade=2244ff=0.1")
end

function update(dt)
	if (mcontroller.liquidPercentage() < 0.30) then	--only apply when submerged
		animator.setParticleEmitterActive("dripshealing", true)
	else
		animator.setParticleEmitterActive("dripshealing", false)
	end
	applyFilteredModifiers({
		speedModifier = 0.97,
		airJumpModifier = 0.97
	})
end

function uninit()
	filterModifiers({},true)
end
