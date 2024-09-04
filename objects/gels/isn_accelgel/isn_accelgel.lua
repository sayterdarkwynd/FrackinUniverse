require "/stats/effects/fu_statusUtil.lua"

function init()
	animator.setParticleEmitterOffsetRegion("yellow", mcontroller.boundBox())
	animator.setParticleEmitterActive("yellow", true)
	animator.setParticleEmitterOffsetRegion("cyan", mcontroller.boundBox())
	animator.setParticleEmitterActive("cyan", true)
end

function update(dt)
	applyFilteredModifiers({
		groundMovementModifier = 0.75,
		speedModifier = 0.75,
		airJumpModifier = 0.5
	})
end

function uninit()
	filterModifiers({},true)
end
