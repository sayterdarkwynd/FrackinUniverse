require "/stats/effects/fu_statusUtil.lua"

function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
end

function update(dt)
	mcontroller.controlParameters({
		normalGroundFriction = 1,
		groundForce = 25,
		slopeSlidingFactor = 0.162
	})
	applyFilteredModifiers({
		groundMovementModifier = 0.8,
		speedModifier = 0.77,
		airJumpModifier = 0.8
	})
end

function uninit()
	filterModifiers({},true)
end
