require "/scripts/unifiedGravMod.lua"

function init()
	--unifiedGravMod.initSoft()
	--unifiedGravMod.init()

  activateVisualEffects()
  self.liquidMovementParameter = {
    groundForce = 70,
    airForce = 20,
    airFriction = 0.3,
    liquidForce = 70,
    liquidFriction = 0.35,
    liquidImpedance = 0.1,
    liquidBuoyancy = 0.25,
    minimumLiquidPercentage = 0.1,
    liquidJumpProfile = {
      jumpSpeed = 70.0,
      jumpControlForce = 610.0,
      jumpInitialPercentage = 0.45,
      jumpHoldTime = 0.01,
      multiJump = false,
      reJumpDelay = 0.5,
      autoJump = false,
      collisionCancelled = false
    }
  }

  script.setUpdateDelta(5)
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
  --unifiedGravMod.update(dt)
  mcontroller.controlParameters(self.liquidMovementParameter)
end
