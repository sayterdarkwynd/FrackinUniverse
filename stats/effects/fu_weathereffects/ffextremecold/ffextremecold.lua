function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=00BBFF=0.15")

  script.setUpdateDelta(5)

  local slows = status.statusProperty("slows", {})
  slows["frostslow"] = 0.75
  status.setStatusProperty("slows", slows)
  self.tickDamagePercentage = 0.04
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecold", 5.0)
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 2,
        damageSourceKind = "nitrogenweapon",
        sourceEntityId = entity.id()
      })
  end
  
end

function uninit()
  local slows = status.statusProperty("slows", {})
  slows["frostslow"] = nil
  status.setStatusProperty("slows", slows)
end