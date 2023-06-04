require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", projectile.die)
  message.setHandler("trigger", trigger)
end

function update(dt)
  if projectile.timeToLive() > 0 then
    projectile.setTimeToLive(0.5)
  end

  if self.delayTimer then
    self.delayTimer = self.delayTimer - dt
    if self.delayTimer <= 0 then
      activate()
      projectile.die()
      self.delayTimer = nil
    end
  end
end

function trigger(_, _, delayTime)
  self.delayTimer = delayTime
end

function activate()
  projectile.processAction(projectile.getParameter("explosionAction"))
end
