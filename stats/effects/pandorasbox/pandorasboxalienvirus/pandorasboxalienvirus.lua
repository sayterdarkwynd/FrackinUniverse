function init()
  animator.setParticleEmitterOffsetRegion("diseasebubbles", mcontroller.boundBox())
  animator.setParticleEmitterActive("diseasebubbles", true)
  effect.addStatModifierGroup({{stat = "healthRegen", amount = -0.5}})

  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.015
  self.tickTime = 4.5
  self.tickTimer = self.tickTime
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "poison",
        sourceEntityId = entity.id()
      })
  end

  effect.setParentDirectives(string.format("fade=00AA00=%.1f", self.tickTimer * 0.4))
end

function uninit()

end
