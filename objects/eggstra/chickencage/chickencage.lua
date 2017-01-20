function init(virtual)
  if not virtual then
    storage.mParams = entity.configParameter("cagedParams", nil)
    entity.setInteractive(storage.mParams ~= nil)
  end
end

function main()
  if entity.id() and storage.mParams == nil then
    local position = entity.position()
    local monsterIds = world.monsterQuery(position, 2, { callScript = "cageCreature" })
    for _,mId in ipairs(monsterIds) do
      local mParams = world.callScriptedEntity(mId, "cageCreature", true)
      if mParams ~= nil then
        storage.mParams = mParams
        updateCage()
        break
      end
    end
  end
end

function onInteraction(args)
  if storage.mParams then
    local p = entity.position()
    world.spawnMonster(storage.mParams.type, {p[1], p[2] + 2}, storage.mParams)
    storage.mParams = nil
    updateCage()
  end
end

function die()
  if storage.mParams then
    updateCage()
  end
end

function updateCage()
  local position = entity.position()
  local direction = entity.direction()
  local mParams = storage.mParams
  local cage = "chickencage"
  if mParams ~= nil then cage = "filledchickencage" end
  storage.mParams = nil
  entity.smash()
  
  --TODO try delay after smash?
  --local result = world.placeObject(cage, position, direction, {cagedParams = mParams})
  --if not result then
    world.spawnItem(cage, position, 1, {cagedParams = mParams})
  --end
end