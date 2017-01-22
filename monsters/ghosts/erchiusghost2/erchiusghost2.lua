require "/scripts/vec2.lua"
require "/scripts/interp.lua"
require "/scripts/util.lua"

function init()
  monster.setDeathParticleBurst("deathPoof")

  message.setHandler("despawn", despawn)

  self.targetId = config.getParameter("target")
  self.speedupRange = config.getParameter("speedupRange")
  self.maxSpeed = config.getParameter("maxSpeed")

  self.erchiusRange = config.getParameter("erchiusRange")
  self.minSpeedRange = config.getParameter("minSpeedRange")
  self.speedupFunction = config.getParameter("speedupFunction")
  self.targetErchius = 0

  self.emissionRange = config.getParameter("emissionRange")
  self.maxEmissionRate = config.getParameter("maxEmissionRate")

  if config.getParameter("uniqueId") then
    monster.setUniqueId(config.getParameter("uniqueId"))
  end

  self.targetErchius = 0
  message.setHandler("setErchiusLevel", function(_,_,amount) 
    self.targetErchius = amount
  end)

  self.despawnTimer = 5.0
end

function minSpeed()
  local ratio = math.min(1.0, math.max(0.0, self.targetErchius / (self.erchiusRange[2] - self.erchiusRange[1])))
  return interp.linear(math.sqrt(ratio), self.minSpeedRange[1], self.minSpeedRange[2])
end

function despawn()
  monster.setDropPool(nil)
  monster.setDeathParticleBurst(nil)
  monster.setDeathSound(nil)
  status.addEphemeralEffect("monsterdespawn")
end

function shouldDie()
  if not status.resourcePositive("health") then return true end

  return false
end

function update(dt)
  if self.targetId and world.entityExists(self.targetId) then
    local targetPosition = world.entityPosition(self.targetId)
    local toTarget = vec2.norm(world.distance(targetPosition, mcontroller.position()))
    local targetDistance = world.magnitude(targetPosition, mcontroller.position())

    local speedDistanceRatio = math.max(0.0, math.min(1.0, (targetDistance - self.speedupRange[1]) / (self.speedupRange[2] - self.speedupRange[1])))
    local speed = minSpeed() + (speedDistanceRatio * self.maxSpeed)
    mcontroller.controlApproachVelocity(vec2.mul(toTarget, speed), mcontroller.baseParameters().airForce)
    mcontroller.controlFace(util.toDirection(toTarget[1]))

    local emissionDistanceRatio = 1 - math.min(1.0, targetDistance / self.emissionRange)
    animator.setParticleEmitterEmissionRate("erchius", emissionDistanceRatio * self.maxEmissionRate)
    if targetDistance < self.emissionRange then
      animator.setGlobalTag("near", "near.")
    else
      animator.setGlobalTag("near", "")
    end
  else
    animator.setGlobalTag("near", "")
    self.despawnTimer = self.despawnTimer - dt
    if self.despawnTimer < 0 then
      despawn()
    end
  end
end