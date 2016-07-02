require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

function setupAltAbility(altAbilityConfig)
  local charge = WeaponAbility:new(altAbilityConfig, altAbilityConfig.stances)

  function charge:init()
    self:reset()
  end

  function charge:update(dt, fireMode, shiftHeld)
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    if self.weapon.currentAbility == nil and self.fireMode == "alt" and not status.resourceLocked("energy") then
      self:setState(self.charge)
    end
  end

  function charge:charge()
    self.weapon:setStance(self.stances.charge)
    self.weapon:updateAim()

    animator.setAnimationState("dashSwoosh", "charge")

    local chargeTimer = 0
    local chargeLevel = 0
    while self.fireMode == "alt" and (chargeLevel == self.chargeLevels or status.overConsumeResource("energy", (self.maxEnergyUsage / self.chargeTime) * self.dt)) do
      chargeTimer = math.min(self.chargeTime, chargeTimer + self.dt)
      chargeLevel = self:setChargeLevel(chargeTimer, chargeLevel)
      coroutine.yield()
    end

    if chargeTimer > self.minChargeTime then
      self:setState(self.dash, chargeTimer / self.chargeTime)
    end
  end

  function charge:dash(charge)
    self.weapon:setStance(self.stances.dash)
    self.weapon:updateAim()

    self:setLightning(3, self.dashLightning[1], self.dashLightning[2], self.dashLightning[3], self.dashLightning[4], 8)

    animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")
    animator.setAnimationState("swoosh", "fire")
    animator.setAnimationState("dashSwoosh", "full")
    animator.playSound("fire")
    
    util.wait(self.maxDashTime * charge, function(dt)
      local aimDirection = {mcontroller.facingDirection() * math.cos(self.weapon.aimAngle), math.sin(self.weapon.aimAngle)}
      mcontroller.controlApproachVelocity(vec2.mul(aimDirection, self.dashMaxSpeed), self.dashControlForce)
      mcontroller.controlParameters({
        airFriction = 0,
        groundFriction = 0,
        liquidFriction = 0,
        gravityEnabled = false  
      })

      local damageArea = partDamageArea("dashSwoosh")
      self.damageConfig.baseDamage = self.baseDps * self.chargeTime * charge
      self.weapon:setDamage(self.damageConfig, damageArea)
    end)

    -- freeze in mid air for a short amount of time
    util.wait(self.freezeTime, function(dt)
      mcontroller.controlParameters({
        gravityEnabled = false  
      })
      mcontroller.setVelocity({0,0})
    end)
  end

  function charge:reset()
    activeItem.setScriptedAnimationParameter("lightning", {})
    animator.setAnimationState("dashSwoosh", "idle")
  end

  function charge:uninit()
    self:reset()
    if self.weapon.currentState == self.dash then
      mcontroller.setVelocity({0,0})
    end
  end

  function charge:setChargeLevel(chargeTimer, currentLevel)
    local level = math.min(self.chargeLevels, math.ceil(chargeTimer / self.chargeTime * self.chargeLevels))
    if currentLevel < level then
      local lightningCharge = self.lightningChargeLevels[level]
      self:setLightning(3, lightningCharge[1], lightningCharge[2], lightningCharge[3], lightningCharge[4], 2.75 + level)
    end
    return level
  end

  function charge:setLightning(amount, width, forks, branching, color, length)
    local lightning = {}
    for i = 1, amount do
      local bolt = {
        minDisplacement = 0.125,
        forks = forks,
        forkAngleRange = 0.75,
        width = width,
        color = color,
        endPointDisplacement = -branching + (i * 2 * branching)
      }
      bolt.startLine = vec2.rotate(vec2.add(self.weapon.weaponOffset, {0, 4.0}), self.weapon.relativeWeaponRotation)
      bolt.endLine = vec2.rotate(vec2.add(self.weapon.weaponOffset, {0, 4.0 - length}), self.weapon.relativeWeaponRotation)
      bolt.displacement = vec2.mag(vec2.sub(bolt.endLine, bolt.startLine)) / 4
      table.insert(lightning, bolt)
    end
    activeItem.setScriptedAnimationParameter("lightning", lightning)
  end

  return charge
end
