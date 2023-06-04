function init()
  animator.setParticleEmitterOffsetRegion("slimey", mcontroller.boundBox())
  animator.setParticleEmitterActive("slimey", true)
end

function update(dt)
  mcontroller.controlParameters({
        normalGroundFriction = 0.5,
        groundForce = 30,
        slopeSlidingFactor = 0.5
    })
end

function uninit()

end