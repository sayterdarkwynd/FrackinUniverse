function init()
  self.gravityModifier = config.getParameter("gravityModifier")
  self.movementParams = mcontroller.baseParameters()
  activateVisualEffects()
  self.liquidMovementParameter = {
    gravityMultiplier = 0.75,
    groundForce = 80,
    airForce = 50,
    airFriction = 0.5,
    liquidForce = 20,
    liquidFriction = 0.1,
    liquidImpedance = 0.1,
    liquidBuoyancy = 0.1,
    minimumLiquidPercentage = 0.2,
    liquidJumpProfile = {
      jumpSpeed = 70.0,
      jumpControlForce = 550.0,
      jumpInitialPercentage = 0.75,
      jumpHoldTime = 0.05,
      multiJump = false,
      reJumpDelay = 1.05,
      autoJump = false,
      collisionCancelled = true
    }
  }  
end



function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function update(dt)
  mcontroller.controlParameters(self.liquidMovementParameter)
end

function uninit()

end
