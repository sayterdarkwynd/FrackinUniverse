require "/scripts/vec2.lua"
require "/scripts/util.lua"

EffectZone = WeaponAbility:new()

function EffectZone:init()
  self.elementalType = self.elementalType or self.weapon.elementalType

  self.stances = config.getParameter("stances")
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.cooldownTime
  self.activeTimer = 0
  self.activeTime = self.activeTime

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function EffectZone:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy") then

    self:setState(self.charge)
  end
  if self.active then
    self.activeTimer = math.max(0, self.activeTimer - self.dt)
    if self.activeTimer <= 0 then
      self:deactivate()
    end
  end
end

-- Attack state: charge
function EffectZone:charge()
  self.weapon:setStance(self.stances.charge)

  animator.playSound(self.elementalType.."charge")
  animator.setAnimationState("charge", "charge")

  local chargeTimer = self.stances.charge.duration

  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end

  animator.stopAllSounds(self.elementalType.."charge")

  if chargeTimer <= 0 then
    self:setState(self.charged)
  else
    animator.playSound(self.elementalType.."discharge")
    self:setState(self.cooldown)
  end
end

function EffectZone:charged()
  self.weapon:setStance(self.stances.charged)

  animator.playSound(self.elementalType.."fullcharge")
  animator.playSound(self.elementalType.."chargedloop", -1)
  animator.setParticleEmitterActive(self.elementalType.."charge", true)

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end

  animator.stopAllSounds(self.elementalType.."chargedloop")

  self:setState(self.discharge)
end

function EffectZone:discharge()
  self.weapon:setStance(self.stances.discharge)

  if status.overConsumeResource("energy", self.energyCost) then
    animator.playSound(self.elementalType.."active")
  else
    animator.playSound(self.elementalType.."discharge")
    self:setState(self.cooldown)
    return
  end

  util.wait(self.stances.discharge.duration, function(dt)

  end)

  self:setState(self.cooldown)
end

function EffectZone:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  animator.setAnimationState("charge", "discharge")
  animator.setParticleEmitterActive(self.elementalType.."charge", false)
  self:activate()
  util.wait(self.stances.cooldown.duration, function()

  end)
end

function EffectZone:activate()
  status.setPersistentEffects("entropicWarding", { "entropicward" })
  animator.playSound(self.elementalType.."activate")
  animator.setAnimationState("charge", "discharge")
  animator.setParticleEmitterActive(self.elementalType.."charge", false)
  if not self.active then
    animator.playSound(self.elementalType.."active", -1)
  end
  self.active = true
  self.activeTimer = self.activeTime
end

function EffectZone:deactivate()
  status.clearPersistentEffects("entropicWarding")
  animator.stopAllSounds(self.elementalType.."active")
  animator.playSound(self.elementalType.."deactivate")
  self.active = false
end

function EffectZone:reset()
  self.deactivate()
  self.weapon:setStance(self.stances.idle)
  animator.stopAllSounds(self.elementalType.."chargedloop")
  animator.stopAllSounds(self.elementalType.."fullcharge")
  animator.setAnimationState("charge", "idle")
  animator.setParticleEmitterActive(self.elementalType.."charge", false)
end

function EffectZone:uninit(weaponUninit)
  self:reset()
end
