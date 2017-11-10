function init()
  --Instantly spawn the pet when first created
  storage.spawnTimer = storage.spawnTimer and 0.5 or 0
  storage.petParams = storage.petParams or {}

  self.monsterType = config.getParameter("shipPetType", "petcat")
  self.spawnOffset = config.getParameter("spawnOffset", {0, 2})
end

function hasPet()
  return self.petId ~= nil
end

function setPet(entityId, params)
  if self.petId == nil or self.petId == entityId then
    self.petId = entityId
    storage.petParams = params
  else
    return false
  end
end

function update(dt)
  if self.petId and not world.entityExists(self.petId) then
    self.petId = nil
  end

  if storage.spawnTimer < 0 and self.petId == nil then
    storage.petParams.level = 1
    self.petId = world.spawnMonster(self.monsterType, object.toAbsolutePosition(self.spawnOffset), storage.petParams)
    world.callScriptedEntity(self.petId, "setAnchor", entity.id())
    storage.spawnTimer = 0.5
  else
    storage.spawnTimer = storage.spawnTimer - dt
  end
end
