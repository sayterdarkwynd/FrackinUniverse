function init()
  animator.setParticleEmitterOffsetRegion("iceslip", mcontroller.boundBox())
  animator.setParticleEmitterActive("iceslip", true)
end

function update(dt)
  mcontroller.controlParameters({
        normalGroundFriction = 0.12,
        groundForce = 8.5,
        slopeSlidingFactor = 0.645
    })
end

function uninit()

end