function setInteractive(state)
  if entity.setInteractive then entity.setInteractive(state)
  else object.setInteractive(state) end
end

function configParameter(name,default)
  if entity.configParameter then
    return entity.configParameter(name,default)
  else
    return config.getParameter(name,default)
  end
end

function init(virtual)
  if not virtual then
--  printTable(0,_ENV)
    setInteractive(true)
  end
end

function onInteraction(args)
  if args ~= nil and args.sourceId ~= nil then
    local p = entity.position()
    local parameters = {}
    local type = configParameter("botspawner.type")
    parameters.persistent = true
    parameters.damageTeamType = "friendly"
    parameters.aggressive = true
    parameters.damageTeam = 0
    parameters.ownerUuid = world.entityUniqueId(args.sourceId) or args.sourceId
    parameters.selfUuid = sb.makeUuid()
    parameters.level = getLevel()
    parameters.spawnPoint = {p[1], p[2] +1} -- object Y is off by 1 ?
    world.spawnMonster(type, parameters.spawnPoint, parameters)
--    entity.smash()
    world.breakObject(entity.id(),true)
  end
end

function getLevel()
  if world.getProperty("ship.fuel") ~= nil then return 1 end
  if world.threatLevel then return (world.threatLevel() + 1) end  
  return 1
end

