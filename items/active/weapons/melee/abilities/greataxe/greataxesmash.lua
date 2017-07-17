require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/melee/meleeslash.lua"

-- Hammer primary attack
-- Extends default melee attack and overrides windup and fire
HammerSmash = MeleeSlash:new()
function HammerSmash:init()
  self.stances.windup.duration = self.fireTime - self.stances.preslash.duration - self.stances.fire.duration

  MeleeSlash.init(self)
  self:setupInterpolation()
end

function HammerSmash:windup(windupProgress)
  self.weapon:setStance(self.stances.windup)

  local windupProgress = windupProgress or 0
  local bounceProgress = 0
  while self.fireMode == "primary" and (self.allowHold ~= false or windupProgress < 1) do
    if windupProgress < 1 then
      windupProgress = math.min(1, windupProgress + (self.dt / self.stances.windup.duration))
      self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
    else
      bounceProgress = math.min(1, bounceProgress + (self.dt / self.stances.windup.bounceTime))
      self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:bounceWeaponAngle(bounceProgress)
    end
    coroutine.yield()
  end

  if windupProgress >= 1.0 then
    if math.abs(world.gravity(mcontroller.position())) > 0 then
      if self.stances.preslash then
        self:setState(self.preslash)
      else
        self:setState(self.fire)
      end
    else
      self:setState(self.spin)
    end
  else
    self:setState(self.winddown, windupProgress)
  end
end

function HammerSmash:winddown(windupProgress)
  self.weapon:setStance(self.stances.windup)

  while windupProgress > 0 do
    if self.fireMode == "primary" then
      self:setState(self.windup, windupProgress)
      return true
    end

    windupProgress = math.max(0, windupProgress - (self.dt / self.stances.windup.duration))
    self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
    coroutine.yield()
  end
end

function HammerSmash:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("swoosh", "fire")
  animator.playSound("fire")
  animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")

  local smashMomentum = self.smashMomentum
  smashMomentum[1] = smashMomentum[1] * mcontroller.facingDirection()
  mcontroller.addMomentum(smashMomentum)

  local smashTimer = self.stances.fire.smashTimer
  local duration = self.stances.fire.duration
  while smashTimer > 0 or duration > 0 do
    smashTimer = math.max(0, smashTimer - self.dt)
    duration = math.max(0, duration - self.dt)

    local damageArea = partDamageArea("swoosh")
    if not damageArea and smashTimer > 0 then
      damageArea = partDamageArea("blade")
    end
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)

    if smashTimer > 0 then
      local groundImpact = world.polyCollision(poly.translate(poly.handPosition(animator.partPoly("blade", "groundImpactPoly")), mcontroller.position()))
      if mcontroller.onGround() or groundImpact then
        smashTimer = 0
        if groundImpact then
          animator.burstParticleEmitter("groundImpact")
          animator.playSound("groundImpact")
        end
      end
    end
    coroutine.yield()
  end

  self.cooldownTimer = self:cooldownTime()
end

function HammerSmash:spin()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("swoosh", "fire")
  animator.playSound("fire")
  animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")

  local direction = -mcontroller.facingDirection()

  local spinTimer = self.stances.spin.spinTimer
  while spinTimer > 0 do
    spinTimer = spinTimer - self.dt

    local ratio = 1 - ((spinTimer / self.stances.spin.spinTimer) ^ 2)
    local angle = ratio * self.stances.spin.spinAngle * direction
    mcontroller.setRotation(angle)

    local damageArea = partDamageArea("swoosh")
    if damageArea then
      self.weapon:setDamage(self.damageConfig, poly.rotate(damageArea, angle), self.fireTime)
    end

    coroutine.yield()
  end

  mcontroller.setRotation(0)
  self.cooldownTimer = self:cooldownTime()
end

function HammerSmash:uninit()
  MeleeSlash.uninit(self)
  if self.weapon.currentState == self.spin then
    mcontroller.setRotation(0)
  end
end

function HammerSmash:setupInterpolation()
  for i, v in ipairs(self.stances.windup.bounceWeaponAngle) do
    v[2] = interp[v[2]]
  end
  for i, v in ipairs(self.stances.windup.bounceArmAngle) do
    v[2] = interp[v[2]]
  end
  for i, v in ipairs(self.stances.windup.weaponAngle) do
    v[2] = interp[v[2]]
  end
  for i, v in ipairs(self.stances.windup.armAngle) do
    v[2] = interp[v[2]]
  end
end

function HammerSmash:bounceWeaponAngle(ratio)
  local weaponAngle = interp.ranges(ratio, self.stances.windup.bounceWeaponAngle)
  local armAngle = interp.ranges(ratio, self.stances.windup.bounceArmAngle)

  return util.toRadians(weaponAngle), util.toRadians(armAngle)
end

function HammerSmash:windupAngle(ratio)
  local weaponRotation = interp.ranges(ratio, self.stances.windup.weaponAngle)
  local armRotation = interp.ranges(ratio, self.stances.windup.armAngle)

  return util.toRadians(weaponRotation), util.toRadians(armRotation)
end
