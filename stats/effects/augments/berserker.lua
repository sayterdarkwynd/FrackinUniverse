function init()
  local bounds = mcontroller.boundBox()
  
    status.setPersistentEffects("berserk", {
      {stat = "maxHealth", baseMultiplier = status.stat("maxHealth")*0.8 },
      {stat = "powerMultiplier", baseMultiplier = status.stat("powerMultiplier")*1.2 }
    })  
end

function update(dt)

end

function uninit()
  
end