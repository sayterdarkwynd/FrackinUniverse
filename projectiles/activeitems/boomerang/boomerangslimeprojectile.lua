require "/scripts/vec2.lua"

function init()
  self.returning = config.getParameter("returning", false)
  self.returnOnHit = config.getParameter("returnOnHit", false)
  self.controlForce = config.getParameter("controlForce")
  self.pickupDistance = config.getParameter("pickupDistance")
  self.snapDistance = config.getParameter("snapDistance")
  self.timeToLive = config.getParameter("timeToLive")
  self.speed = config.getParameter("speed")
  self.ignoreTerrain = config.getParameter("ignoreTerrain")
  self.ownerId = projectile.sourceEntity()
  self.minVelocity = config.getParameter("minVelocity", 0.2)

  if self.ignoreTerrain then mcontroller.applyParameters({collisionEnabled=false}) end

  if boomerangExtra then
    boomerangExtra:init()
  end
end

function update(dt)
  if self.ownerId and world.entityExists(self.ownerId) then
    if boomerangExtra then
      boomerangExtra:update(dt)
    end

    if not self.returning then
      if self.controlForce then mcontroller.approachVelocity({0, 0}, self.controlForce) end
      if (not self.ignoreTerrain and mcontroller.isColliding()) or vec2.mag(mcontroller.velocity()) < self.minVelocity then
        self.returning = true
      end
    else
      local toTarget = world.distance(world.entityPosition(self.ownerId), mcontroller.position())
      if self.pickupDistance and (vec2.mag(toTarget) < self.pickupDistance) then
        projectile.die()
       elseif self.timeToLive and (projectile.timeToLive() < self.timeToLive * 0.5) then
        mcontroller.applyParameters({collisionEnabled=false})
        mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.speed), 500)
      elseif self.snapDistance and (vec2.mag(toTarget) < self.snapDistance) then
        mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.speed), 500)
      elseif self.controlForce then
        mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.speed), self.controlForce)
      end
    end
  else
    projectile.die()
  end
end

function hit(entityId)
  if self.returnOnHit then self.returning = true end
end

function boomerangProjectileIds()
  if boomerangExtra and boomerangExtra.boomerangProjectileIds then
    return boomerangExtra:boomerangProjectileIds()
  else
    return {entity.id()}
  end
end
