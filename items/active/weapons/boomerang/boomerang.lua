require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/activeitem/stances.lua"

function init()
  self.critChance = config.getParameter("critChance", 0)
  self.critBonus = config.getParameter("critBonus", 0)
  self.projectileType = config.getParameter("projectileType")
  self.projectileParameters = config.getParameter("projectileParameters")
  self.projectileParameters.power = self.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))
  initStances()

  self.cooldownTime = config.getParameter("cooldownTime", 0)
  self.cooldownTimer = self.cooldownTime

  checkProjectiles()
  if storage.projectileIds then
    setStance("throw")
  else
    setStance("idle")
  end
end



  -- *******************************************************
  -- FU Crit Damage Script

function setCritDamageBoomerang(damage)
	if not self.critChance then 
		self.critChance = config.getParameter("critChance", 0)
	end
	if not self.critBonus then
		self.critBonus = config.getParameter("critBonus", 0)
	end
     -- check their equipped weapon
     -- Primary hand, or single-hand equip  
     local heldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand())
     --used for checking dual-wield setups
     local opposedhandHeldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand() == "primary" and "alt" or "primary")  
     local weaponModifier = config.getParameter("critChance",0)
     
  if heldItem then
     if root.itemHasTag(heldItem, "boomerang") or root.itemHasTag(heldItem, "chakram") then
        self.critChance = 0.35 + weaponModifier
      end
  end
    --sb.logInfo("crit chance base="..self.critChance)
    --apply the crit 
  --critBonus is bonus damage done with crits
  self.critBonus = ( ( ( ((status.stat("critBonus") or 0) + config.getParameter("critBonus",0)) * self.critChance ) /100 ) /2 ) or 0  
  -- this next modifier only applies if they have a multiply item equipped
  self.critChance = (self.critChance  + config.getParameter("critChanceMultiplier",0)+ status.stat("critChanceMultiplier",0) + status.stat("critChance",0)) 
  -- random dice roll. I've heavily lowered the chances, as it was far too high by nature of the random roll.
  self.critRoll = math.random(200)
  

  local crit = self.critRoll <= self.critChance
    --sb.logInfo("crit roll="..self.critRoll)
  damage = crit and (damage*2) + self.critBonus or damage

  if crit then
    if heldItem then
      -- exclude mining lasers
      if not root.itemHasTag(heldItem, "mininggun") then 
        status.addEphemeralEffect("crithit", 0.3, activeItem.ownerEntityId())
      end
    end
  end

  return damage
end
  -- *******************************************************


function update(dt, fireMode, shiftHeld)
  updateStance(dt)
  checkProjectiles()

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.stanceName == "idle" and fireMode == "primary" and self.cooldownTimer == 0 then
    self.cooldownTimer = self.cooldownTime
    setStance("windup")
  end

  if self.stanceName == "throw" then
    if not storage.projectileIds then
      setStance("catch")
    end
  end

  updateAim()
end

function uninit()

end

function fire()
  if world.lineTileCollision(mcontroller.position(), firePosition()) then
    setStance("idle")
    return
  end

  local params = copy(self.projectileParameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.ownerAimPosition = activeItem.ownerAimPosition()
  
  params.power = setCritDamageBoomerang(params.power)
  
  if self.aimDirection < 0 then params.processing = "?flipx" end
  local projectileId = world.spawnProjectile(
      self.projectileType,
      firePosition(),
      activeItem.ownerEntityId(),
      aimVector(),
      false,
      params
    )
  if projectileId then
    storage.projectileIds = {projectileId}
  end
  animator.playSound("throw")
end

function checkProjectiles()
  if storage.projectileIds then
    local newProjectileIds = {}
    for i, projectileId in ipairs(storage.projectileIds) do
      if world.entityExists(projectileId) then
        local updatedProjectileIds = world.callScriptedEntity(projectileId, "projectileIds")

        if updatedProjectileIds then
          for j, updatedProjectileId in ipairs(updatedProjectileIds) do
            table.insert(newProjectileIds, updatedProjectileId)
          end
        end
      end
    end
    storage.projectileIds = #newProjectileIds > 0 and newProjectileIds or nil
  end
end
