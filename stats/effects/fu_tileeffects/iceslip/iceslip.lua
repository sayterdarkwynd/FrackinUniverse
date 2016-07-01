function init()
  animator.setParticleEmitterOffsetRegion("iceslip", mcontroller.boundBox())
  animator.setParticleEmitterActive("iceslip", true)
end

function update(dt)
  mcontroller.controlParameters({
        normalGroundFriction = 0.52,
        groundForce = 23.5,
        slopeSlidingFactor = 0.375
    })
end

function uninit()

end