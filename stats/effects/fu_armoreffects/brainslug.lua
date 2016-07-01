function init()
  animator.setParticleEmitterOffsetRegion("slug", mcontroller.boundBox())
  animator.setParticleEmitterActive("slug", true)
end

function update(dt)
  mcontroller.controlParameters({
        gravityMultiplier = 1.15,
        airForce = 35.0,
        groundForce = 23.5,
        runSpeed = 17.0,
      airJumpProfile = {
        jumpSpeed = 32.5,
        jumpControlForce = 980.0,
        jumpInitialPercentage = 0.85
      },
    })
end

function uninit()

end
