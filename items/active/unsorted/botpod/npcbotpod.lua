require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/activeitem/stances.lua"

function init()
  initStances()

  local pets = config.getParameter("pets")
  self.pet = pets[math.random(#pets)]

  self.projectileId = nil
  self.returnProjectileId = nil
  setStance("idle")

  animator.setGlobalTag("health", "healthy")
end

function update(dt, fireMode, shiftHeld)
  checkProjectiles()

  updateStance(dt)

  if fireMode ~= "primary" then
    self.fired = false
  end

  if self.stanceName == "idle" then
    if fireMode == "primary" and not self.fired then
      self.fired = true
      setStance("windup")
    end
  end

  updateAim()

  if self.stanceName == "throw" then
    if not self.projectileId and not self.returnProjectileId then
      consumePod()
    end
  end
end

function consumePod()
  local entityId = activeItem.ownerEntityId()
  if world.entityType(entityId) == "npc" then
    world.callScriptedEntity(entityId, "setItemSlotDelayed", activeItem.hand())
  elseif world.entityType(entityId) == "player" then
    activeItem.takeOwnerItem(item.descriptor())
  end
end

function checkProjectiles()
  if self.projectileId then
    if not world.entityExists(self.projectileId) then
      self.projectileId = nil
    elseif world.callScriptedEntity(self.projectileId, "monstersReleased") then
      self.returnProjectileId = self.projectileId
      self.projectileId = nil
    end
  elseif self.returnProjectileId then
    if not world.entityExists(self.returnProjectileId) then
      self.returnProjectileId = nil
    end
  end
end

function fire()
  if self.pet and not self.projectileId and not self.returnProjectileId then
    throwProjectile()
    setStance("throw")
  end
end

function monsterLevel()
  local entityId = activeItem.ownerEntityId()
  if world.entityType(entityId) == "npc" then
    return world.callScriptedEntity(entityId, "npc.level") or 1
  end
  return 1
end

function throwProjectile()
  local position = firePosition()

  local params = config.getParameter("projectileParameters")

  params.monsterType = self.pet
  params.monsterLevel = monsterLevel()

  params.ownerAimPosition = activeItem.ownerAimPosition()
  if self.aimDirection < 0 then params.processing = "?flipx" end

  self.projectileId = world.spawnProjectile(
      config.getParameter("projectileType"),
      position,
      activeItem.ownerEntityId(),
      aimVector(),
      false,
      params
    )
  animator.playSound("throw")
end
