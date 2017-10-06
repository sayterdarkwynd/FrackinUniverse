function init()
    status.setPersistentEffects("berserk", {
      {stat = "maxHealth", baseMultiplier = 0.8 },
      {stat = "powerMultiplier", baseMultiplier = 1.2 }
    })  
end

function update(dt)

end

function uninit()
  status.clearPersistentEffects("berserk")
end