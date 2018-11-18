require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"

shockwaveAttack = {
  shockwaveBounds = {},
  shockwaveHeight = 0,
  maxDistance = 0,
  impactLine = {},
  directions = {}
}

function shockwaveAttack.loadConfig()
  shockwaveAttack.setConfig(
    config.getParameter("projectileType", "physicalshockwave"),
    config.getParameter("projectileConfig", { power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * 10 }),
    config.getParameter("shockwaveBounds", {-0.4, -1.375, 0.4, 0.0}),
    config.getParameter("shockwaveHeight", 1.375),
    config.getParameter("maxDistance", 12),
    config.getParameter("impactLine", {{1.25, -1.5}, {1.25, -4.5}}),
    config.getParameter("directions", {1})
  )
end

function shockwaveAttack.setConfig(projectile, projectileConfig, shockwaveBounds, shockwaveHeight ,maxDistance, impactLine, directions)
  if projectile then shockwaveAttack.projectile = projectile end

  if projectileConfig then
    if projectileConfig.power then
      projectileConfig.power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * projectileConfig.power
    end
    shockwaveAttack.projectileConfig = projectileConfig
  end

  shockwaveAttack.shockwaveBounds = shockwaveBounds
  shockwaveAttack.shockwaveHeight = shockwaveHeight
  shockwaveAttack.maxDistance = maxDistance
  shockwaveAttack.impactLine = impactLine
  shockwaveAttack.directions = directions
end

function shockwaveAttack.fireShockwave()
  local impact, impactHeight = shockwaveAttack.impactPosition()

  if impact then
    local charge = math.floor(shockwaveAttack.maxDistance)
    local positions = shockwaveAttack.shockwaveProjectilePositions(impact, charge, shockwaveAttack.directions)
    if #positions > 0 then
      local params = shockwaveAttack.projectileConfig
      params.actionOnReap = {
        {
          action = "projectile",
          inheritDamageFactor = 1,
          type = shockwaveAttack.projectile
        }
      }
      for i,position in pairs(positions) do
        local xDistance = world.distance(position, impact)[1]
        local dir = util.toDirection(xDistance)
        params.timeToLive = (math.floor(math.abs(xDistance))) * 0.025
        world.spawnProjectile("shockwavespawner", position, entity.id(), {dir,0}, false, params)
      end
    end
  end
end

function shockwaveAttack.impactPosition()
  local dir = mcontroller.facingDirection()
  local startLine = vec2.add(mcontroller.position(), vec2.mul(shockwaveAttack.impactLine[1], {dir, 1}))
  local endLine = vec2.add(mcontroller.position(), vec2.mul(shockwaveAttack.impactLine[2], {dir, 1}))
  local blocks = world.collisionBlocksAlongLine(startLine, endLine, {"Null", "Block"})

  if #blocks > 0 then
    return vec2.add(blocks[1], {0.5, 0.5}), endLine[2] - blocks[1][2] + 1
  end
end

function shockwaveAttack.shockwaveProjectilePositions(impactPosition, maxDistance, directions)
  local positions = {}

  for _,direction in pairs(directions) do
    direction = direction * mcontroller.facingDirection()
    local position = copy(impactPosition)
    for i = 0, maxDistance do
      local continue = false
      for _,yDir in ipairs({0, -1, 1}) do
        local wavePosition = {position[1] + direction * i, position[2] + 0.5 + yDir + shockwaveAttack.shockwaveHeight}
        local groundPosition = {position[1] + direction * i, position[2] + yDir}
        local bounds = rect.translate(shockwaveAttack.shockwaveBounds, wavePosition)

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
