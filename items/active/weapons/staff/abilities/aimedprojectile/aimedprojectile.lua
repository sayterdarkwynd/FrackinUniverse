require "/scripts/vec2.lua"
require "/scripts/util.lua"

ControlProjectile = WeaponAbility:new()

function ControlProjectile:init()
  self.elementalType = self.elementalType or self.weapon.elementalType

  self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
  self.stances = config.getParameter("stances")

  activeItem.setCursor("/cursors/reticle0.cursor")
  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function ControlProjectile:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  world.debugPoint(self:focusPosition(), "blue")

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy") then

    self:setState(self.chargerotate)
  end
end

-- charge
function ControlProjectile:chargerotate()
  self.weapon:setStance(self.stances.chargerotate)

  animator.playSound(self.elementalType.."charge")
  animator.setAnimationState("charge", "charge")
  animator.setParticleEmitterActive(self.elementalType .. "charge", true)
  activeItem.setCursor("/cursors/charge2.cursor")

  local chargeTimer = self.stances.chargerotate.duration
  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end

  animator.stopAllSounds(self.elementalType.."charge")

  if chargeTimer <= 0 then
    self:setState(self.chargedrotate)
  else
    animator.playSound(self.elementalType.."discharge")
    self:setState(self.cooldown)
  end
end

-- charged
function ControlProjectile:chargedrotate()
  self.weapon:setStance(self.stances.chargedrotate)

  animator.playSound(self.elementalType.."fullcharge")
  animator.playSound(self.elementalType.."chargedloop", -1)
  animator.setParticleEmitterActive(self.elementalType .. "charge", true)

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end

  self:setState(self.dischargerotate)
end

-- discharge
function ControlProjectile:dischargerotate()
  self.weapon:setStance(self.stances.dischargerotate)

  activeItem.setCursor("/cursors/reticle0.cursor")

  animator.playSound(self.elementalType.."activate")
  self:createProjectiles()

  util.wait(self.stances.dischargerotate.duration, function(dt)
    status.setResourcePercentage("energyRegenBlock", 1.0)
  end)

  animator.playSound(self.elementalType.."discharge")
  animator.stopAllSounds(self.elementalType.."chargedloop")

  self:setState(self.cooldown)
end

-- cooldown
function ControlProjectile:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon.aimAngle = 0

  animator.setAnimationState("charge", "discharge")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")

  util.wait(self.stances.cooldown.duration, function()

  end)
end

-- create projectile
function ControlProjectile:createProjectiles()
  local position = self.focusPosition()
  local aim = self.weapon.aimAngle

  local pParams = copy(self.projectileParameters)
  pParams.power = self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier")
  pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

  if not world.lineTileCollision(mcontroller.position(), position) then
    world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {mcontroller.facingDirection() * math.cos(aim), math.sin(aim)}, false, params)
  end
end

-- stone offset
function ControlProjectile:focusPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

-- stop sounds and particles
function ControlProjectile:reset()
  self.weapon:setStance(self.stances.idle)
  animator.stopAllSounds(self.elementalType.."chargedloop")
  animator.stopAllSounds(self.elementalType.."fullcharge")
  animator.setAnimationState("charge", "idle")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")
end

-- reset
function ControlProjectile:uninit(weaponUninit)
  self:reset()
end
