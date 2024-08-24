function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	effect.setParentDirectives("fade=7733AA=0.1")
end
