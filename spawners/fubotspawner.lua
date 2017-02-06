require "/scripts/util.lua"
require "/scripts/companions/util.lua"
require "/scripts/messageutil.lua"

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

function init()
  if true then
--  printTable(0,_ENV)
    setInteractive(true)
  end
end

function onInteraction(args)
  if args ~= nil and args.sourceId ~= nil then
    local p = entity.position()
    local parameters = {}
    local type = configParameter("botspawner.type")
    sb.logInfo("Spawning a servitor. Type is %s",type)
    parameters.persistent = true
    parameters.damageTeamType = "friendly"
    parameters.aggressive = true
    parameters.damageTeam = 0
    parameters.ownerUuid = world.entityUniqueId(args.sourceId) or args.sourceId
    parameters.selfUuid = sb.makeUuid()
    parameters.level = getLevel()
    local spawnPoint = {p[1], p[2] +1} -- object Y is off by 1 ?
    sb.logInfo("Parameters for spawn are: %s",parameters)
    world.spawnMonster(type, spawnPoint, parameters)
--    entity.smash()

    world.breakObject(entity.id(),true)
  end
end

function getLevel()
  if world.getProperty("ship.fuel") ~= nil then return 1 end
  if world.threatLevel then return world.threatLevel() end
  return 1
end
