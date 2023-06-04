require "/scripts/vec2.lua"

function init()
  self.ownerId = projectile.sourceEntity()
end

function update(dt)
  if self.ownerId and world.entityExists(self.ownerId) then
    if mcontroller.stickingDirection() then
      projectile.setTimeToLive(0.5)
    end
  else
    kill()
  end
end

function anchored()
  return mcontroller.stickingDirection()
end

function kill()
  self.dead = true
end

function shouldDestroy()
  return self.dead or projectile.timeToLive() <= 0
end
