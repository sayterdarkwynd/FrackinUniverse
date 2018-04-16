function init()
  animator.setParticleEmitterOffsetRegion("metalspeed", mcontroller.boundBox())
  animator.setParticleEmitterActive("metalspeed", true)
end

function update(dt)
  mcontroller.controlParameters({
        groundForce = 120.0,
        walkSpeed = 14.0,
        runSpeed = 22.0,
    })
end

function uninit()

end