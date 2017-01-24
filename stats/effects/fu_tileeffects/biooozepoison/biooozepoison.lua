function init()
  _x = config.getParameter("healthDown", 0)
baseValue = config.getParameter("healthDown",0)*(status.resourceMax("health"))

  --if (status.resourceMax("health")) * _x >= 100.0 then
  --   effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  --   else
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  --end

  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)

  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.02
  self.tickTime = 2.0
  self.tickTimer = self.tickTime
end

function update(dt)

  if status.isResource("food") then
      hungerLevel = status.resource("food")
  else
      hungerLevel = 50
  end

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
      damageSourceKind = "poison",
      sourceEntityId = entity.id()
    })
    if status.isResource("food") then
      adjustedHunger = hungerLevel - (hungerLevel * 0.0095)
      status.setResource("food", adjustedHunger)
    end
  end

  effect.setParentDirectives("fade=CCFF33="..self.tickTimer * 0.4)

end

function uninit()

end
