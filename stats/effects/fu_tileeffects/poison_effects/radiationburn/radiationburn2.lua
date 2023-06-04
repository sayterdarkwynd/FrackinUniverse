function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  animator.setParticleEmitterActive("fx", true)
  effect.setParentDirectives("fade=00FF33=0.15")
  script.setUpdateDelta(20)
  self.tickDamagePercentage = 0.03
  self.tickTime = 1
  self.tickTimer = self.tickTime
  self.currentDebuff = 0.0
  self.debuffPerSec = -0.20 -- Lose 20% phys resist per second
  self.maxDebuff = -status.stat("physicalResistance")
end

function update(dt)
  if (status.stat("radioactiveResistance",0)  >= 0.4) or status.statPositive("biomeradiationImmunity") or status.statPositive("ffextremeradiationImmunity") then
    effect.expire()
  end
  local maxDebuff=self.maxDebuff*((status.statPositive("specialStatusImmunity") and 0.25) or 1)
  self.tickTimer = self.tickTimer - dt
  self.currentDebuff = math.max(self.currentDebuff + self.debuffPerSec * dt, maxDebuff)
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime

    -- Incrementally debuff target's physical resistance. --
    status.setPersistentEffects("aciddust2", { {stat = "physicalResistance", amount = self.currentDebuff } })

    -- Apply damage if target's physical resistance is as low as this effect can make it (otherwise, just make the 'hurt' SFX). --
    local dmg = 0.1
    if (self.currentDebuff == maxDebuff) then
      if status.statPositive("specialStatusImmunity") then
          dmg = math.floor(world.threatLevel() * self.tickDamagePercentage * 100)
      else
          dmg = math.floor((status.resourceMax("health") * self.tickDamagePercentage) + (world.threatLevel()/3))
      end
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
  status.clearPersistentEffects("aciddust2")
end
