function init()
  self.gravityModifier = effect.configParameter("gravityModifier")
  self.movementParams = mcontroller.baseParameters()
  activateVisualEffects()
  self.liquidMovementParameter = {
    gravityMultiplier = 0.95,
    groundForce = 100,
    airForce = 50,
    airFriction = 0.5,
    liquidForce = 30,
    liquidFriction = 0.0,
    liquidImpedance = 0.24,
    liquidBuoyancy = 0.92,
    minimumLiquidPercentage = 0.5,
    liquidJumpProfile = {
      jumpSpeed = 60.0,
      jumpControlForce = 1150.0,
      jumpInitialPercentage = 0.75,
      jumpHoldTime = 0.2,
      multiJump = false,
      reJumpDelay = 0.05,
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
