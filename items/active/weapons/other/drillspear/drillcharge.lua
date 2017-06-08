require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

DrillCharge = WeaponAbility:new()

function DrillCharge:init()
  self:reset()
end

function DrillCharge:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  if self.weapon.currentAbility == nil
      and self.fireMode == "alt"
      and not status.statPositive("activeMovementAbilities")
      and not status.resourceLocked("energy") then

    self:setState(self.windup)
  end
end

function DrillCharge:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  animator.playSound("windup")

  animator.setAnimationState("drill", "active2")
  animator.setAnimationState("energy", "windup1")

  util.wait(self.stances.windup.duration / 2)

  animator.setAnimationState("energy", "windup2")

  util.wait(self.stances.windup.duration / 2)

  self:setState(self.charge)
end

function DrillCharge:charge()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("energy", "active2")
  animator.setParticleEmitterActive("charge", true)

  self.tileDamageTimer = 0

  
  while self.fireMode == "alt" and status.overConsumeResource("energy", self.energyUsage * self.dt) do
    self.weapon:updateAim()

    local boostAngle = mcontroller.facingDirection() == 1 and self.weapon.aimAngle or math.pi - self.weapon.aimAngle
    mcontroller.controlApproachVelocityAlongAngle(boostAngle, self.boostSpeed, self.boostForce, true)

    local damageArea = partDamageArea("drillenergy")
    self.weapon:setDamage(self.damageConfig, damageArea, self.damageTimeout)

    self.tileDamageTimer = math.max(0, self.tileDamageTimer - self.dt)
    if self.tileDamageTimer == 0 then
      self.tileDamageTimer = self.tileDamageRate
      self:damageTiles()
    end

    coroutine.yield()
  end

  animator.setParticleEmitterActive("charge", false)

  self:setState(self.winddown)
end

function DrillCharge:winddown()
  self.weapon:setStance(self.stances.winddown)
  self.weapon:updateAim()

  status.clearPersistentEffects("weaponMovementAbility")

  animator.playSound("winddown")

  animator.setAnimationState("energy", "windup2")

  util.wait(self.stances.winddown.duration / 2)

  animator.setAnimationState("energy", "windup1")

  util.wait(self.stances.winddown.duration / 2)
end

function DrillCharge:reset()
  status.clearPersistentEffects("weaponMovementAbility")
  animator.setAnimationState("drill", "idle")
  animator.setAnimationState("energy", "idle")
end

function DrillCharge:uninit()
  self:reset()
end

function DrillCharge:damageTiles()
  local pos = mcontroller.position()
  local tipPosition = vec2.add(pos, activeItem.handPosition(animator.partPoint("drillenergy", "drillTip")))
  for i = 1, 3 do
    local sourcePosition = vec2.add(pos, activeItem.handPosition(animator.partPoint("drillenergy", "drillSource" .. i)))
    local drillTiles = world.collisionBlocksAlongLine(sourcePosition, tipPosition, nil, self.damageTileDepth)
    if #drillTiles > 0 then
      world.damageTiles(drillTiles, "foreground", sourcePosition, "blockish", self.tileDamage, 99)
      world.damageTiles(drillTiles, "background", sourcePosition, "blockish", self.tileDamage, 99)
    end
  end
end
