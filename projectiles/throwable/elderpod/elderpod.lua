require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.returns = config.getParameter("returns", true)
  self.releaseOnHit = config.getParameter("releaseOnHit", true)
  self.controlForce = config.getParameter("controlForce")
  self.pickupDistance = config.getParameter("pickupDistance")
  self.snapDistance = config.getParameter("snapDistance")
  self.speed = config.getParameter("speed")
  self.returnCollisionDuration = config.getParameter("returnCollisionDuration")
  self.pureArcDuration = config.getParameter("pureArcDuration")
  self.returnCollisionPoly = config.getParameter("returnCollisionPoly")
  self.podUuid = config.getParameter("podUuid")
  self.ownerId = projectile.sourceEntity()

  self.returnElapsed = 0
  self.returning = false
end

function update(dt)
  if not mcontroller.isColliding() then
    self.preCollisionVelocity = mcontroller.velocity()
  end
 
  if self.ownerId and world.entityExists(self.ownerId) then

    if not self.returning then
      mcontroller.setRotation(0)
      if mcontroller.isColliding() or vec2.mag(mcontroller.velocity()) < 0.1 then
        releaseMonsters()
      end
    else
      self.returnElapsed = self.returnElapsed + dt

      local toTarget = world.distance(world.entityPosition(self.ownerId), mcontroller.position())
      local targetDistance = vec2.mag(toTarget)
      if targetDistance < self.pickupDistance then
        projectile.die()
      elseif self.returnElapsed > self.returnCollisionDuration or targetDistance < self.snapDistance then
        mcontroller.applyParameters({collisionEnabled = false})
        mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.speed), 500)
      elseif self.returnElapsed > self.pureArcDuration then
        mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.speed), self.controlForce)
      end
    end
  else
    projectile.die()
  end
end

function hit(entityId)
  if self.releaseOnHit and not self.returning then
    releaseMonsters()
  end
end

function releaseMonsters()
  if self.podUuid then
    -- Player filledcapturepod
    world.sendEntityMessage(self.ownerId, "pets.spawnFromPod", self.podUuid, mcontroller.position())

    if self.returns then
      self.returning = true
      mcontroller.applyParameters({
          collisionPoly = self.returnCollisionPoly
        })
      mcontroller.setVelocity(vec2.mul(self.preCollisionVelocity or mcontroller.velocity(), -1))
    else
      projectile.die()
    end
  else
    -- NPC npcpetcapturepod
    local monsterType = config.getParameter("monsterType")
    local damageTeam = entity.damageTeam()
    local entityId = world.spawnMonster(monsterType, mcontroller.position(), {
        level = config.getParameter("monsterLevel", 1),
        damageTeam = damageTeam.team,
        damageTeamType = damageTeam.type,
        aggressive = true
      })
    local position = world.callScriptedEntity(entityId, "findGroundPosition", world.entityPosition(entityId), -10, 10, false)
    if position then
      world.callScriptedEntity(entityId, "mcontroller.setPosition", position)
    end

    projectile.die()

  end
end

function monstersReleased()
  return self.returning
end
