require "/scripts/unifiedGravMod.lua"

function init()
  unifiedGravMod.init()
  self.gravityMod = config.getParameter("gravityMod",0)
  effect.addStatModifierGroup({effect="gravityMod",amount=self.gravityMod})
  self.movementParams = mcontroller.baseParameters()
  activateVisualEffects()
  self.liquidMovementParameter = {
    --gravityMultiplier = 1.5,
    groundForce = 100,
    airForce = 20,
    airFriction = 0,
    liquidForce = 100,
    liquidFriction = 0.0,
    liquidImpedance = 0.01,
    liquidBuoyancy = 0.01,
    liquidJumpProfile = {
      jumpSpeed = 55.0,
      jumpControlForce = 900.0,
      jumpInitialPercentage = 1,
      jumpHoldTime = 0.1,
      multiJump = false,
      autoJump = false,
      reJumpDelay = 0.5
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
