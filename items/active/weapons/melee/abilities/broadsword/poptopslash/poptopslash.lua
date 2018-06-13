require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

KunaiBlast = WeaponAbility:new()

function KunaiBlast:init()
  self.cooldownTimer = self.cooldownTime
end

function KunaiBlast:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
      and self.fireMode == "alt"
      and self.cooldownTimer == 0
      and not status.statPositive("activeMovementAbilities")
      and status.overConsumeResource("energy", self.energyUsage) then

    self:setState(self.windup)
  end
end

function KunaiBlast:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  util.wait(self.stances.windup.duration)

  if not status.statPositive("activeMovementAbilities") then
    self:setState(self.fire)
  end
end

function KunaiBlast:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  local projectileTimesAndAngles = copy(self.projectileTimesAndAngles)

  util.wait(self.stances.fire.duration, function(dt)
      mcontroller.controlApproachVelocity({0, 0}, 1000)

      local newTimesAndAngles = {}
      for _, timeAndAngle in pairs(projectileTimesAndAngles) do
        if timeAndAngle[1] <= dt then
          self:spawnProjectile(timeAndAngle[2])
        else
          table.insert(newTimesAndAngles, {timeAndAngle[1] - dt, timeAndAngle[2]})
        end
      end
      projectileTimesAndAngles = newTimesAndAngles
    end)

  self.cooldownTimer = self.cooldownTime
end

function KunaiBlast:spawnProjectile(angleAdjust)
  local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * self.weapon.aimDirection, self.projectileOffset[2]})
  local params = {
    powerMultiplier = activeItem.ownerPowerMultiplier(),
    power = self:damageAmount()
  }
  local aimVector = vec2.withAngle(util.toRadians(angleAdjust))
  aimVector[1] = aimVector[1] * self.weapon.aimDirection
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), aimVector, false, params)
  animator.playSound("fireKunai")
end

function KunaiBlast:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function KunaiBlast:uninit()
  status.clearPersistentEffects("weaponMovementAbility")
end
