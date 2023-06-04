require "/scripts/vec2.lua"

ControlProjectile = WeaponAbility:new()

function ControlProjectile:init()
  storage.projectiles = storage.projectiles or {}

  self.cooldownTimer = self.cooldownTime
end

function ControlProjectile:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.cooldownTimer == 0 and not self.weapon.currentAbility and not status.resourceLocked("energy") and self.fireMode == "alt" then
    self.reaim()
  end
end

function ControlProjectile.reaim()
  local aimPosition = activeItem.ownerAimPosition()
  for _, projectileId in pairs(storage.projectiles) do
    if world.entityExists(projectileId) then
      world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
    end
  end
  self.cooldownTimer = self.cooldownTime
end

function ControlProjectile:uninit()
end
