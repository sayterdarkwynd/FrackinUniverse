require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"

-- Helper functions
function fireShockwave()
  local impact = impactPosition()

  if impact then
    local charge = math.floor(config.getParameter("maxDistance"))
    local directions = {1, -1}
    local positions = shockwaveProjectilePositions(impact, charge, directions)
    if #positions > 0 then
      --need to scale the power
      local params = copy(config.getParameter("projectileParameters"))
      params.power = scalePower(params.power)
      params.actionOnReap = {
        {
          action = "projectile",
          inheritDamageFactor = 1,
          type = config.getParameter("projectileType")
        }
      }
      for _,position in pairs(positions) do
        local xDistance = world.distance(position, impact)[1]
        local dir = util.toDirection(xDistance)
        params.timeToLive = (math.floor(math.abs(xDistance))) * 0.025
        world.spawnProjectile("shockwavespawner", position, activeItem.ownerEntityId(), {dir,0}, false, params)
      end
    end
  end
end

function impactPosition()
  local position = mcontroller.position()
  local bounds = mcontroller.boundBox()
  local offset = {0,bounds[2]}
  return vec2.add(position, offset)
end

function shockwaveProjectilePositions(impactPosition, maxDistance, directions)
  local positions = {}

  for _,direction in pairs(directions) do
    direction = direction * mcontroller.facingDirection()
    local position = copy(impactPosition)
    for i = 0, maxDistance do
      local continue = false
      for _,yDir in ipairs({0, -1, 1}) do
        local wavePosition = {position[1] + direction * i, position[2] + 0.5 + yDir + config.getParameter("shockwaveHeight")}
        local groundPosition = {position[1] + direction * i, position[2] + yDir}
        local bounds = rect.translate(config.getParameter("shockwaveBounds"), wavePosition)

        if world.pointTileCollision(groundPosition, {"Null", "Block", "Dynamic", "Slippery"}) and not world.rectTileCollision(bounds, {"Null", "Block", "Dynamic", "Slippery"}) then
          table.insert(positions, wavePosition)
          position[2] = position[2] + yDir
          continue = true
          break
        end
      end
      if not continue then break end
    end
  end

  return positions
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
