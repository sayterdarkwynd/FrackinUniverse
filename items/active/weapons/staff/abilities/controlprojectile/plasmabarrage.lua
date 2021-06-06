require "/items/active/weapons/staff/abilities/controlprojectile/controlprojectile.lua"

function ControlProjectile:createProjectiles()
  local aimPosition = activeItem.ownerAimPosition()
  local fireDirection = world.distance(aimPosition, self:focusPosition())[1] > 0 and 1 or -1
  local pOffset = {fireDirection * (self.projectileDistance or 0), 0}
  local basePos = activeItem.ownerAimPosition()

  local pCount = self.projectileCount or 1
  -- bonus projectiles
  if self.staffMasteryBase > 0.95 then
      self.bonusProjectiles = 6
  elseif self.staffMasteryBase > 0.80 then
     self.bonusProjectiles = 5
  elseif self.staffMasteryBase > 0.60 then
     self.bonusProjectiles = 4
  elseif self.staffMasteryBase > 0.40 then
     self.bonusProjectiles = 3
  elseif self.staffMasteryBase > 0.20 then
     self.bonusProjectiles = 2
  else
     self.bonusProjectiles = 1
  end
  pCount = pCount + self.bonusProjectiles

  local pParams = copy(self.projectileParameters)
  pParams.power = self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
  pParams.powerMultiplier = activeItem.ownerPowerMultiplier() * self.staffMastery 

  for i = 1, pCount do
    pParams.delayTime = self.projectileDelayFirst + (i - 1) * self.projectileDelayEach
    pParams.periodicActions = jarray()
    table.insert(pParams.periodicActions, {
        time = pParams.delayTime,
        ["repeat"] = false,
        action = "sound",
        options = self.triggerSound
      })

    local projectileId = world.spawnProjectile(
        self.projectileType,
        vec2.add(basePos, pOffset),
        activeItem.ownerEntityId(),
        pOffset,
        false,
        pParams
      )

    if projectileId then
      table.insert(storage.projectiles, projectileId)
      world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
    end

    pOffset = vec2.rotate(pOffset, (2 * math.pi) / pCount)
  end
end
