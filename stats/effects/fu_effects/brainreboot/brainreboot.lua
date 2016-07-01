function update(dt)
    animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
    animator.setParticleEmitterActive("healing", true)
    healP = effect.configParameter("healPercent", 0) -- Heal percent is the configParameter in the json statuseffects file
    self.healingRate = (status.resourceMax("health") * healP) / effect.duration()
end

function heal(damage)
end

function selfDamage(notification) --take damage
    if (status.resourcePercentage("health") <= 0.25) then --checks health level, change 0.1 to whatever below 1
      --status.modifyResource("health", notification.damage / 2)
      status.modifyResource("health", self.healingRate * dt)
      status.clearPersistentEffects("brainreboot")
    end
end

function clear()
end