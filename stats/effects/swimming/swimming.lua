function init()
  self.applyToTypes = config.getParameter("applyToTypes") or {"player", "npc"}

  self.mouthPosition = status.statusProperty("mouthPosition") or {0,0}
  self.mouthBounds = {self.mouthPosition[1], self.mouthPosition[2], self.mouthPosition[1], self.mouthPosition[2]}
  self.setWet = false

  animator.setParticleEmitterOffsetRegion("bubbles", self.mouthBounds)

  --prevents fall damage from occuring while underwater
  effect.addStatModifierGroup({{stat = "fallDamageMultiplier", effectiveMultiplier = 0.0}})
end

function allowedType()
  local entityType = entity.entityType()
  for _,applyType in ipairs(self.applyToTypes) do
    if entityType == applyType then
      return true
    end
  end
end

function update(dt)
  if not allowedType() then return false end

  local position = mcontroller.position()
  local worldMouthPosition = {
    self.mouthPosition[1] + position[1],
    self.mouthPosition[2] + position[2]
  }

  local liquidAtMouth = world.liquidAt(worldMouthPosition)
  if liquidAtMouth and (liquidAtMouth[1] == 1 or liquidAtMouth[1] == 2) then
    animator.setParticleEmitterActive("bubbles", true)
    self.setWet = true
  else
    animator.setParticleEmitterActive("bubbles", false)
  end

  status.removeEphemeralEffect("wet")
end

function onExpire()
  if self.setWet then
    status.addEphemeralEffect("wet")
  end
end
