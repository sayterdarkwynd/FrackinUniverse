require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

FlipSlash = WeaponAbility:new()

function FlipSlash:init()
  self.cooldownTimer = self.cooldownTime
end

function FlipSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  if self.weapon.currentAbility == nil and self.fireMode == "alt" and not status.resourceLocked("energy") then
    if mcontroller.onGround() then self:setState(self.windup)
    else
      self.weapon:setStance(self.stances.windup)
      util.wait(0.1, function(dt)
          mcontroller.controlCrouch()
        end)
      self:setState(self.flip)
    end
  end
end

function FlipSlash:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration, function(dt)
      mcontroller.controlCrouch()
    end)

  self:setState(self.flip)
end

function FlipSlash:flip()
  while self.fireMode == "alt" and not status.resourceLocked("energy") do
    self.weapon:setStance(self.stances.flip)
    self.weapon:updateAim()

    animator.setAnimationState("swoosh", "flip")
    animator.playSound(self.fireSound or "flipSlash")
    animator.setParticleEmitterActive("flip", true)

    self.flipTime = self.rotations * self.rotationTime
    self.flipTimer = 0

    self.jumpTimer = self.jumpDuration
    while self.flipTimer < self.flipTime do
      mcontroller.clearControls()
      mcontroller.controlModifiers({runningSuppressed=true})
      mcontroller.controlModifiers({speedModifer=35.0})
      self.flipTimer = self.flipTimer + self.dt

      mcontroller.controlParameters(self.flipMovementParameters)

      if self.jumpTimer > 0 then
        self.jumpTimer = self.jumpTimer - self.dt
        mcontroller.setYVelocity(self.jumpVelocity[2]) --heh
      end

      local damageArea = partDamageArea("swoosh")
      self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)

      mcontroller.setRotation(-math.pi * 2 * self.weapon.aimDirection * (self.flipTimer / self.rotationTime))

      coroutine.yield()
    end
  end
  status.clearPersistentEffects("weaponMovementAbility")

  animator.setAnimationState("swoosh", "idle")
  mcontroller.setRotation(0)
  animator.setParticleEmitterActive("flip", false)
  self.cooldownTimer = self.cooldownTime
end

function FlipSlash:uninit()
  status.clearPersistentEffects("weaponMovementAbility")
  animator.setAnimationState("swoosh", "idle")
  mcontroller.setRotation(0)
  animator.setParticleEmitterActive("flip", false)
end
