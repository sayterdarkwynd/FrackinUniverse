require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

FlipSlash = WeaponAbility:new()

function FlipSlash:init()
  self.cooldownTimer = self.cooldownTime
  self.wasOnGround = false
  self.energyUsage = self.energyUsage or 20
end

function FlipSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if mcontroller.onGround() or mcontroller.liquidMovement() or mcontroller.zeroG() then
	self.wasOnGround = true
  end

  if self.cooldownTimer > 0 and not (self.cooldownOnGroundOnly and not self.wasOnGround) then
    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    if self.cooldownTimer == 0 then
      animator.playSound("recharge")
    end
  end

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and not status.resourceLocked("energy") then
    self:setState(self.windup)
  end
end

function FlipSlash:windup()
  self.weapon:setStance(self.stances.windup)

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  util.wait(self.stances.windup.duration, function(dt)
    if self.stances.windup.crouch == true then
      mcontroller.controlCrouch()
    end
  end)

  self:setState(self.flip)
end

function FlipSlash:flip()
-- consume energy
  status.overConsumeResource("energy", self.energyUsage)

  self.facingDirection = mcontroller.facingDirection()
  self.weapon:setStance(self.stances.flip)
  self.weapon:updateAim()
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  status.addEphemeralEffect("invulnerable")
  animator.setParticleEmitterActive("dashParticles", true)

  self.flipTime = self.rotations * self.rotationTime
  self.flipTimer = 0

  self.jumpTimer = self.jumpDuration

  while self.flipTimer < self.flipTime do
    self.flipTimer = self.flipTimer + self.dt

    mcontroller.controlParameters(self.flipMovementParameters)

    if self.jumpTimer > 0 then
      self.jumpTimer = self.jumpTimer - self.dt
      mcontroller.setVelocity({self.jumpVelocity[1] * self.weapon.aimDirection, self.jumpVelocity[2]})
    end

    mcontroller.setRotation(math.pi * 2 * self.weapon.aimDirection * (self.flipTimer / self.rotationTime))

    coroutine.yield()
  end

  if self.stopAfterFlip then
    local movementParams = mcontroller.baseParameters()
    local currentVelocity = mcontroller.velocity()
    if math.abs(currentVelocity[1]) > movementParams.runSpeed then
      mcontroller.setVelocity({movementParams.runSpeed * self.facingDirection, 0})
    end
    mcontroller.controlApproachXVelocity(self.facingDirection * movementParams.runSpeed, self.flipControlForce)
  elseif self.slowAfterFlip then
	mcontroller.setXVelocity(self.jumpVelocity[1] * self.slowDownFactor * self.facingDirection)
  end

  status.clearPersistentEffects("weaponMovementAbility")

  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
  self.wasOnGround = false

  mcontroller.setRotation(0)
  self.cooldownTimer = self.cooldownTime
  status.removeEphemeralEffect("invulnerable")
end


function FlipSlash:uninit()
  status.clearPersistentEffects("weaponMovementAbility")
  mcontroller.setRotation(0)
end
