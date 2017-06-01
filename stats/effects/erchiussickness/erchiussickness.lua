require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.effectMaxErchius = config.getParameter("effectMaxErchius")
  self.effectDistance = config.getParameter("effectDistance")
  self.emissionRate = config.getParameter("emissionRate")
  self.desaturateAmount = config.getParameter("desaturateAmount")
  self.light = config.getParameter("lightColor")
  self.multiply = config.getParameter("multiplyColor")

  self.maxDps = config.getParameter("maxDps")
  self.damageDistance = config.getParameter("damageDistance")

  self.monsterUniqueId = string.format("%s-ghost", world.entityUniqueId(entity.id()) or sb.makeUuid())
  self.findMonster = util.uniqueEntityTracker(self.monsterUniqueId, 0.2)
  self.saturation = 0

  self.dps = 0

  self.spawnTimer = 0.5
end

function update(dt)
  local erchiusCount = 0
  erchiusCount = erchiusCount + (world.entityHasCountOfItem(entity.id(), "liquidfuel") or 0)
  erchiusCount = erchiusCount + (world.entityHasCountOfItem(entity.id(), "solidfuel") or 0)
  erchiusCount = erchiusCount + (world.entityHasCountOfItem(entity.id(), "supermatter") or 0)
  local erchiusRatio = math.sqrt(math.min(1.0, erchiusCount / self.effectMaxErchius))
  if erchiusCount > 0 and self.spawnTimer > 0 then
    self.spawnTimer = self.spawnTimer - dt
  end

  status.modifyResource("health", -self.dps * dt)

  local monsterPosition = self.findMonster()
  if monsterPosition then
    if not self.messaged then
      world.sendEntityMessage(entity.id(), "queueRadioMessage", "erchiussickness")
      self.messaged = true
    end

    local distance = world.distance(monsterPosition, mcontroller.position())
    animator.resetTransformationGroup("smoke")
    animator.rotateTransformationGroup("smoke", vec2.angle(distance))

    local damageDistanceRatio = 1 - math.min(1.0, math.max(0.0, vec2.mag(distance) / self.damageDistance))
    self.dps = damageDistanceRatio * self.maxDps

    local effectDistance = interp.linear(erchiusRatio, self.effectDistance[1], self.effectDistance[2])
    local effectDistanceRatio = 1 - math.min(1.0, math.max(0.0, vec2.mag(distance) / effectDistance))
    animator.setParticleEmitterEmissionRate("smoke", self.emissionRate * effectDistanceRatio)
    animator.setParticleEmitterActive("smoke", effectDistanceRatio > 0)

    self.saturation = math.floor(-self.desaturateAmount * effectDistanceRatio)

    world.sendEntityMessage(self.monsterUniqueId, "setErchiusLevel", erchiusCount)
  elseif monsterPosition == nil then
    self.saturation = 0
    animator.setLightActive("glow", false)

    if self.spawnTimer < 0 then
      local parameters = {
        level = world.threatLevel(),
        target = entity.id(),
        aggressive = true,
        uniqueId = self.monsterUniqueId,
        keepAlive = true
      }
      world.spawnMonster("erchiusghost", vec2.add(mcontroller.position(), config.getParameter("ghostSpawnOffset")), parameters)
      self.spawnTimer = 1.0
    end
  end

  animator.setLightColor("glow", {self.light[1] * erchiusRatio, self.light[2] * erchiusRatio, self.light[3] * erchiusRatio})
  animator.setLightActive("glow", true)

  local multiply = {255 + self.multiply[1] * erchiusRatio, 255 + self.multiply[2] * erchiusRatio, 255 + self.multiply[3] * erchiusRatio}
  local multiplyHex = string.format("%s%s%s", toHex(multiply[1]), toHex(multiply[2]), toHex(multiply[3]))
  effect.setParentDirectives(string.format("?saturation=%d?multiply=%s", self.saturation, multiplyHex))
end

function toHex(num)
  local hex = string.format("%X", math.floor(num + 0.5))
  if num < 16 then hex = "0"..hex end
  return hex
end

function uninit()
end
