function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  animator.setParticleEmitterActive("fx", true)
  effect.setParentDirectives("fade=00FF33=0.15")
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.02
  self.tickTime = 0.2
  self.tickTimer = self.tickTime
  self.currentDebuff = 0.0
  self.debuffPerSec = -0.15 -- Lose 15% phys resist per second
  self.maxDebuff = -status.stat("physicalResistance",0)
end

function update(dt)
  if (status.stat("radioactiveResistance",0)  >= 0.4) or status.statPositive("biomeradiationImmunity") or status.statPositive("ffextremeradiationImmunity") then
    effect.expire()
  end

  self.tickTimer = self.tickTimer - dt
  self.currentDebuff = self.currentDebuff + self.debuffPerSec * dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    if self.currentDebuff >= self.maxDebuff then
      status.setPersistentEffects("aciddust", { {stat = "physicalResistance", amount = self.currentDebuff } })
      -- Apply a tiny amount of damage for "hurt" noise --
      status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = 0.1,
        damageSourceKind = "radioactive",
        sourceEntityId = entity.id()
      })
    else
      status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage),
        damageSourceKind = "radioactive",
        sourceEntityId = entity.id()
      })
    end
  end
end

function uninit()
  status.clearPersistentEffects("aciddust")
end
