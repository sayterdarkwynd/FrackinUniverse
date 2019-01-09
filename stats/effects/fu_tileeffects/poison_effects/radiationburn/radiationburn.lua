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
  self.currentDebuff = math.max(self.currentDebuff + self.debuffPerSec * dt, self.maxDebuff)
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    -- Incrementally debuff target's physical resistance. --
    status.setPersistentEffects("aciddust", { {stat = "physicalResistance", amount = self.currentDebuff } })
    -- Apply damage if target's physical resistance is zero (otherwise, just make the 'hurt' SFX). --
    local dmg = 0.1
    if (self.currentDebuff == self.maxDebuff) then
      dmg = math.floor(status.resourceMax("health") * self.tickDamagePercentage)
    end
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = dmg,
      damageSourceKind = "radioactive",
      sourceEntityId = entity.id()
    })
  end
end

function uninit()
  status.clearPersistentEffects("aciddust")
end
