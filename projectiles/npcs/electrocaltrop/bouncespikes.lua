require "/scripts/vec2.lua"

function uninit()
  bounce()
end

function bounce()
  local spikeProjectile = config.getParameter("spikeProjectile")
  local spikeDamageFactor = config.getParameter("spikeDamageFactor")

  local checkDistance = config.getParameter("spikeCheckDistance", 0.75)
  local checkDirections = config.getParameter("spikeCheckDirections", 6)

  local spikesRemaining = config.getParameter("maxSpikes", 2)

  local pos = mcontroller.position()

  for i = 1, checkDirections do
    local thisAngle = math.pi * 2 * (i / checkDirections)
    local thisVector = vec2.rotate({checkDistance, 0}, thisAngle)

    local collidePoint = world.lineCollision(pos, vec2.add(pos, thisVector))
    if collidePoint then
      local params = {}
      params.power = projectile.power() * spikeDamageFactor
      params.powerMultiplier = projectile.powerMultiplier()

      world.spawnProjectile(
        spikeProjectile,
        collidePoint,
        projectile.sourceEntity(),
        vec2.withAngle(math.random() * 2 * math.pi),
        false,
        params
      )

      spikesRemaining = spikesRemaining - 1
      if spikesRemaining == 0 then
        return
      end
    end
  end
end
