function init()
	animator.setParticleEmitterOffsetRegion("glitch", mcontroller.boundBox())
	animator.setParticleEmitterActive("glitch", true)
	effect.setParentDirectives("fade=DDDDFF=0.5")

	if status.isResource("stunned") then status.setResource("stunned", math.max(status.resource("stunned"), effect.duration())) end
	mcontroller.setVelocity({0, 0})
end

function update(dt)
	if status.isResource("stunned") then status.setResource("stunned", math.max(status.resource("stunned"), effect.duration())) end
	mcontroller.controlModifiers({
		facingSuppressed = true,
		movementSuppressed = true
	})
end
