require "/scripts/vec2.lua"
require "/scripts/poly.lua"

function init()
  self.returning = config.getParameter("returning", false)
  self.pickupDistance = config.getParameter("pickupDistance")
  self.timeToLive = config.getParameter("timeToLive")
  self.speed = config.getParameter("speed")
  self.ownerId = projectile.sourceEntity()

  self.maxDistance = config.getParameter("maxDistance")

  self.initialPosition = mcontroller.position()
  self.distanceTraveled = 0
  self.maxBounces = config.getParameter("maxBounces", 4)
  self.piercing = config.getParameter("piercing", false)
end

function update(dt)
  if self.ownerId and world.entityExists(self.ownerId) then
    if not self.returning then
      if mcontroller.isColliding() then
        self.maxBounces = self.maxBounces - 1
        if self.maxBounces == 0 then
          self.returning = true
        else
          self.maxDistance = self.maxDistance + self.distanceTraveled --reset it.
          self.initialPosition = mcontroller.position()
        end
      else
        self.distanceTraveled = world.magnitude(mcontroller.position(), self.initialPosition)
        if self.distanceTraveled > self.maxDistance then
          self.returning = true
        end
      end
      projectile.setTimeToLive(5)
    else
      mcontroller.applyParameters({collisionEnabled=false})
      local toTarget = world.distance(world.entityPosition(self.ownerId), mcontroller.position())
      if vec2.mag(toTarget) < self.pickupDistance then
        projectile.die()
      else
        mcontroller.setVelocity(vec2.mul(vec2.norm(toTarget), self.speed))
        projectile.setTimeToLive(5)
      end
    end
  else
    projectile.die()
  end
end

function hit(entityId)
  if not self.piercing then
    self.maxBounces = self.maxBounces - 1
    if self.maxBounces == 0 then
      self.returning = true
    else
      self.maxDistance = self.maxDistance + self.distanceTraveled
      self.initialPosition = mcontroller.position()
    end
  end
end

function projectileIds()
  return {entity.id()}
end
