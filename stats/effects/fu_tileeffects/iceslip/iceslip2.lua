function init()
  animator.setParticleEmitterOffsetRegion("iceslip", mcontroller.boundBox())
  animator.setParticleEmitterActive("iceslip", true)
end

function update(dt)
  mcontroller.controlParameters({
        normalGroundFriction = 0.32,
        groundForce = 18.5,
        slopeSlidingFactor = 0.445
    })
end

function uninit()

end