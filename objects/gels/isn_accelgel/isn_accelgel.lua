function init()
  animator.setParticleEmitterOffsetRegion("yellow", mcontroller.boundBox())
  animator.setParticleEmitterActive("yellow", true)
  animator.setParticleEmitterOffsetRegion("cyan", mcontroller.boundBox())
  animator.setParticleEmitterActive("cyan", true)
end

function update(dt)
  mcontroller.controlModifiers({
    groundMovementModifier = 0.75,
	runModifier = 0.75,
	jumpModifier = 0.5
  })
end

function uninit()
end
