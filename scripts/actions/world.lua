-- HELPERS
function entityLevel()
  if entity.entityType() == "monster" then
    return monster.level()
  elseif entity.entityType() == "npc" then
    return npc.level()
  else
    return 1
  end
end

-- ACTIONS

-- output list
function playersInWorld(args, board)
  return true, {list = world.players()}
end

-- param flag
function setUniverseFlag(args, board)
  world.setUniverseFlag(args.flag)
  return true
end


-- ENTITIES

function entityAggressive(args, board)
  if not args.entity or not world.entityExists(args.entity) then return false end
  return world.entityAggressive(args.entity)
end

-- param entity
function entityExists(args, board)
  if args.entity == nil then return false end
  return world.entityExists(args.entity)
end

-- param entity
-- output position
function entityPosition(args, board)
  if args.entity == nil or not world.entityExists(args.entity) then return false end

  local position = world.entityPosition(args.entity)
  return true, {position = position, x = position[1], y = position[2]}
end

-- param position
-- param entity
-- param range
-- param xRange
-- param yRange
function entityInRange(args, board)
  if args.entity == nil or not world.entityExists(args.entity) or args.position == nil then return false end

  local targetPosition = world.entityPosition(args.entity)

  if args.range then
    return world.magnitude(targetPosition, args.position) <= args.range
  elseif args.xRange then
    return math.abs(world.distance(targetPosition, args.position)[1]) <= args.xRange
  elseif args.yRange then
    return math.abs(world.distance(targetPosition, args.position)[2]) <= args.yRange
  else
    return false
  end
end

-- param entity
-- param types
function entityInTypes(args, output)
  if args.entity == nil or args.types == nil then return false end

  local entityType = world.entityType(args.entity)
  for _,acceptedType in pairs(args.types) do
    if entityType == acceptedType then
      return true
    end
  end
  return false
end

-- param entity
-- output number
function entityHealth(args, board)
  local health = world.entityHealth(args.entity)
  if health == nil then return false end

  return true, {number = health[1]}
end

-- param entity
-- output number
function entityHealthPercentage(args, board)
  local health = world.entityHealth(args.entity)
  if health == nil then return false end

  return true, {number = health[1]/health[2]}
end

-- param entity
-- output number
function entityMoney(args, board)
  local money = world.entityCurrency(args.entity, "money")
  if money == nil then return false end

  return true, {number = money}
end

-- param entity
-- param damageTeam
function isNpc(args, board)
  if args.entity == nil then return false end

  return world.isNpc(args.entity, args.damageTeam)
end

-- param entity
-- param func
function callScriptedEntity(args, output)
  if args.entity == nil or args.func == nil then return false end

  return world.callScriptedEntity(args.entity, args.func) == true
end

-- param entity
-- param message
-- param arguments
function sendEntityMessage(args, board)
  if args.entity == nil or args.message == nil then return false end

  world.sendEntityMessage(args.entity, args.message, table.unpack(args.arguments))
  return true
end

-- param uniqueId
-- output entity
function loadUniqueEntity(args, board)
  if not args.uniqueId then return false end

  local entityId = world.loadUniqueEntity(args.uniqueId)
  if not world.entityExists(entityId) then return false end

  return true, {entity = entityId}
end

-- param entity
-- param region
function keepEntityLoaded(args, board)
  if args.entity == nil or not world.entityExists(args.entity) then return false end

  local position = world.entityPosition(args.entity)
  world.loadRegion(rect.translate(args.region, position))
  return true
end

-- param entity
-- param species
function hasSpeciesSpecificDescription(args, board)
  local species = args.species or (entity.entityType() == "npc" and npc.species()) or "human"
  if not args.entity or not world.entityExists(args.entity) then return false end

  -- Return success if the species description is non-generic.
  -- If the description is default (or a duplicate of default) it's not
  -- species-specific
  return world.entityDescription(args.entity, species) ~= world.entityDescription(args.entity)
end

-- param entity
function entityHoldingWeapon(args, board)
  if args.entity == nil then return false end

  local primaryItem = world.entityHandItem(args.entity, "primary")
  local altItem = world.entityHandItem(args.entity, "alt")
  return (primaryItem and root.itemHasTag(primaryItem, "weapon")) or (altItem and root.itemHasTag(altItem, "weapon")) or false
end
-- param entity
-- param itemTag
function entityHandItemTag(args, board)
  local primary, alt = world.entityHandItem(args.entity, "primary"), world.entityHandItem(args.entity, "alt")
  if (primary and root.itemHasTag(primary, args.itemTag)) or (alt and root.itemHasTag(alt, args.itemTag)) then
    return true
  else
    return false
  end
end

-- OBJECTS

-- param entity
function loungableOccupied(args, board)
  if args.entity == nil then return false end

  return world.loungeableOccupied(args.entity) == true
end

-- param entity
function isLoungeable(args, board)
  if args.entity == nil then return false end
  return world.getObjectParameter(args.entity, "objectType") == "loungeable"
end

-- param interactObject
function interactObject(args)
  if args.entity == nil then return false end

  world.callScriptedEntity(args.entity, "onInteraction", {sourceId = entity.id()})
  return true
end

-- param objectEntity
-- param itemName
-- param tag
function hasItemTag(args, board)
  if args.objectEntity then
    if not args.objectEntity or not world.entityExists(args.objectEntity) then return false end

    local tags = world.getObjectParameter(args.objectEntity, "itemTags", {})

    return contains(tags, args.tag) ~= false

  elseif args.itemName then
    return contains(root.itemConfig(args.itemName).config.itemTags or {}, args.tag) ~= false
  end

  return false
end

-- SPAWNING

-- param position
-- param species
-- param type
-- param level
-- param damageTeamType
-- param damageTeam
-- param seed
-- param parameters
function spawnNpc(args, board)
  args.parameters.damageTeam = args.damageTeam
  args.parameters.damageTeamType = args.damageTeamType

  if not args.position or not args.species or not args.npcType or not args.level then
    return false
  end

  local entityId = world.spawnNpc(args.position, args.species, args.npcType, args.level, args.seed, args.parameters)
  world.callScriptedEntity(entityId, "status.addEphemeralEffect", "beamin")
  return true
end

-- param position
-- param type
-- param level
-- param damageTeamType
-- param damageTeam
-- param replacement
-- param parameters
-- param inheritParameters
-- output enittyId
function spawnMonster(args, board)
  if args.position == nil then return false end

  local parameters = args.parameters or {}
  parameters.level = args.level or entityLevel()
  parameters.damageTeamType = args.damageTeamType or entity.damageTeam().type
  parameters.damageTeam = args.damageTeam or entity.damageTeam().team
  parameters.aggressive = parameters.aggressive or config.getParameter("aggressive", true)

  for _, paramName in pairs(args.inheritParameters) do
    parameters[paramName] = config.getParameter(paramName, parameters[paramName])
  end

  if args.replacement then
    assert(monster)
    parameters.scale = config.getParameter("scale")

    if capturable then
      parameters.ownerUuid = config.getParameter("ownerUuid")
      parameters.podUuid = config.getParameter("podUuid")

      if parameters.podUuid then
        parameters.uniqueId = parameters.uniqueId or sb.makeUuid()
      else
        -- This wasn't a pet
      end
    end
  end

  local entityId = world.spawnMonster(args.type, args.position, parameters)
  if args.replacement then
    world.callScriptedEntity(entityId, "status.addPersistentEffects", "miniboss", status.getPersistentEffects("miniboss"))
  end

  if args.replacement and parameters.podUuid and capturable then
    capturable.disassociate()
    capturable.associate({
        name = world.entityName(entityId),
        description = world.entityDescription(entityId),
        portrait = world.entityPortrait(entityId, "full"),
        uniqueId = parameters.uniqueId,
        config = {
            type = args.type,
            parameters = parameters
          },
        collisionPoly = world.callScriptedEntity(entityId, "mcontroller.collisionPoly"),
        status = world.callScriptedEntity(entityId, "capturable.captureStatus")
      })
  end

  return true, {entityId = entityId}
end

-- param position
-- param type
-- param stagehandConfig
function spawnStagehand(args)
  if args.position == nil then return false end

  world.spawnStagehand(args.position, args.type, args.stagehandConfig)
  return true
end

-- also checks microdungeons!
function dungeonId(args, board)
  if args.position == nil then return false end

  local id = world.dungeonId(args.position)
  if id ~= 0 then return true, {dungeonId = id}
  else return false, {dungeonId = 0} end
end
