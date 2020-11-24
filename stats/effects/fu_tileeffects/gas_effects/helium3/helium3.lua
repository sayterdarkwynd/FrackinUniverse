require "/scripts/unifiedGravMod.lua"

function init()
	unifiedGravMod.initSoft()
	unifiedGravMod.init()

  --self.gravityModifier = config.getParameter("gravityModifier")
  --self.movementParams = mcontroller.baseParameters()
  activateVisualEffects()
  self.liquidMovementParameter = {
    --gravityMultiplier = 0.75,
    groundForce = 80,
    airForce = 40,
    airFriction = 0.4,
    liquidForce = 70,
    liquidFriction = 0.1,
    liquidImpedance = 0.1,
    liquidBuoyancy = 0.1,
    minimumLiquidPercentage = 0.1,
    liquidJumpProfile = {
      jumpSpeed = 70.0,
      jumpControlForce = 550.0,
      jumpInitialPercentage = 0.55,
      jumpHoldTime = 0.024,
      multiJump = false,
      reJumpDelay = 0.5,
      autoJump = false,
      collisionCancelled = true
    }
  }
end



function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  if entity.entityType()=="player" then
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  end
end

function update(dt)
	mcontroller.controlParameters(self.liquidMovementParameter)
	unifiedGravMod.update(dt)
end
