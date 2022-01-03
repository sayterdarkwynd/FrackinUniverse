-- Helpers

-- Probably the hackiest thing in all the behavior nodes
-- All of these should be node parameters
function parseProjectileConfig(board, args)
  local parsed = copy(args)
  if parsed.power and type(parsed.power) == "string" then
    parsed.power = board:getNumber(args.power)
  end
  if parsed.speed and type(parsed.speed) == "string" then
    parsed.speed = board:getNumber(args.speed)
  end
  if parsed.timeToLive and type(parsed.timeToLive) == "string" then
    parsed.timeToLive = board:getNumber(args.timeToLive)
  end
  if parsed.animationCycle and type(parsed.animationCycle) == "string" then
    parsed.animationCycle = board:getNumber(args.animationCycle)
  end

  return parsed
end

function scalePower(power)
  local multiplier = 1
  if entity.entityType() == "monster" then
    multiplier = root.evalFunction("monsterLevelPowerMultiplier", monster.level())
  elseif entity.entityType() == "npc" then
    multiplier = root.evalFunction("npcLevelPowerMultiplierModifier", npc.level())
  end

  return (power or 10) * multiplier * status.stat("powerMultiplier")
end

-- param position
-- param offset
-- param projectileType
-- param angle
-- param aimVector
-- param sourceEntity
-- param trackSource
-- param projectileConfig
-- param scalePower
-- param damageRepeatGroup
-- param uniqueRepeatGroup
function spawnProjectile(args, board)
	--sb.logInfo("%s",args)
  local parameters = parseProjectileConfig(board, args.projectileConfig or {})
  if args.scalePower then parameters.power, parameters.level = scalePower(parameters.power) end

  local aimVector = args.aimVector or vec2.withAngle(args.angle) or {0,-1}
  if args.damageRepeatGroup and args.damageRepeatGroup ~= "" then
    parameters.damageRepeatGroup = args.damageRepeatGroup
    if args.uniqueRepeatGroup then
      parameters.damageRepeatGroup = string.format(parameters.damageRepeatGroup.."-%s", entity.id())
    end
  end
  --sb.logInfo("%s", or "nil")
  --sb.logInfo("%s",{pt=args.projectileType or "nil", pos=args.position or "nil", epos=entity.position(), off=args.offset or "nil", src=args.sourceEntity or "nil", aim=aimVector or "nil", tsrc=args.trackSource or "nil", p=parameters or "nil"})
  world.spawnProjectile(args.projectileType, vec2.add(args.position or entity.position(), args.offset), args.sourceEntity, aimVector, args.trackSource, parameters)
  return true
end

-- param position
-- param projectileType
-- param aimVector
-- param trackSource
-- param parameters
-- param target
function spawnTargetedProjectile(args, board)
  local parameters = copy(args.parameters)
  parameters.power, parameters.level = scalePower(parameters.power)

  if not args.target or not world.entityExists(args.target) then return false end

  local projectileId = world.spawnProjectile(args.projectileType, args.position, entity.id(), args.aimVector, args.trackSource, parameters)
  world.sendEntityMessage(projectileId, "setTarget", args.target)
  return true
end

-- param fromPosition
-- param toPosition
-- param speed
-- param gravityMultiplier
-- param collisionCheck
-- param useHighArc
-- output aimVector
-- output aimAngle
function projectileAimVector(args, board)
  if args.fromPosition == nil or args.speed == nil or args.toPosition == nil then return false end
  local gravityMultiplier = args.gravityMultiplier or mcontroller.baseParameters().gravityMultiplier

  local toTarget = world.distance(args.toPosition, args.fromPosition)
  local aimVector, foundVector = util.aimVector(toTarget, args.speed, gravityMultiplier, args.useHighArc)
  if not foundVector then return false end
  aimVector = vec2.norm(aimVector)

  -- Simulate the arc and do basic line and poly collision checks
  if args.collisionCheck then
    local velocity = vec2.mul(aimVector, args.speed)
    local startArc = mcontroller.position()
    local x = 0
    while x < math.abs(toTarget[1]) do
      local time = x / math.abs(velocity[1])
      local yVel = velocity[2] - (gravityMultiplier * world.gravity(mcontroller.position()) * time)
      local step = vec2.add({util.toDirection(aimVector[1]) * x, ((velocity[2] + yVel) / 2) * time}, mcontroller.position())

      if world.lineTileCollision(startArc, step) or world.polyCollision(poly.translate(mcontroller.collisionPoly(), step)) then
        return false
      end

      startArc = step
      local arcVector = vec2.norm({velocity[1], yVel})
      x = x + math.abs(arcVector[1])
    end
  end

  return true, {aimVector = aimVector, aimAngle = vec2.angle(aimVector)}
end

-- param projectileName
-- output gravityMultiplier
function projectileGravityMultiplier(args, board)
  if args.projectileName == nil or args.projectileName == "" then return false end
  return true, {gravityMultiplier = root.projectileGravityMultiplier(args.projectileName)}
end
