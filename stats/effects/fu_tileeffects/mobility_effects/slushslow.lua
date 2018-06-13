function init()
  local slows = status.statusProperty("slows", {})
  slows["slushslow"] = 0.3
  status.setStatusProperty("slows", slows)
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)  
end

function update(dt)
      mcontroller.controlParameters({
        normalGroundFriction = 1,
        groundForce = 25,
        slopeSlidingFactor = 0.162
        })
  mcontroller.controlModifiers({
        groundMovementModifier = 0.8,
        runModifier = 0.77,
        jumpModifier = 0.8
    })
end

function uninit()
  local slows = status.statusProperty("slows", {})
  slows["slushslow"] = nil
  status.setStatusProperty("slows", slows)
end





