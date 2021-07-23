function init()
  animator.setParticleEmitterOffsetRegion("shadowgaseffect", mcontroller.boundBox())
  activateVisualEffects()
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.01
  self.tickTime = 1.2
  self.tickTimer = self.tickTime


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
      reJumpDelay = 1.05,
      autoJump = false,
      collisionCancelled = false
    }
  }
	if status.statPositive("shadowImmunity") or status.statPositive("shadowgasImmunity") or ( status.stat("shadowResistance") > 0.5) then
	  deactivateVisualEffects()
	  effect.expire()
	  return
	end
  animator.setParticleEmitterActive("shadowgaseffect", true)
  effect.setParentDirectives("fade=000000=0.15")
end

function deactivateVisualEffects()
  animator.setParticleEmitterActive("shadowgaseffect", false)
end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("shadowgaseffect", mcontroller.boundBox())
  animator.setParticleEmitterActive("shadowgaseffect", true)
  if entity.entityType()=="player" then
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  end
end

function update(dt)
	if status.statPositive("shadowImmunity") or status.statPositive("shadowgasImmunity") or ( status.stat("shadowResistance") > 0.5) then
	  deactivateVisualEffects()
	  effect.expire()
	  return
	end
	mcontroller.controlParameters(self.liquidMovementParameter)

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
	local damageVal
	if status.statPositive("specialStatusImmunity") then
		damageVal=math.ceil(world.threatLevel() * self.tickDamagePercentage * 100)
	else
		damageVal=math.ceil(status.resourceMax("health") * self.tickDamagePercentage) + 1
	end
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = damageVal,
        damageSourceKind = "shadow",
        sourceEntityId = entity.id()
      })
  end

end

function uninit()

end
