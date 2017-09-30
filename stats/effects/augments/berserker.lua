function init()
  local bounds = mcontroller.boundBox()
  
    status.setPersistentEffects("floranpower1", {
      {stat = "maxHealth", amount = status.stat("maxHealth")*0.8 },
      {stat = "powerMultiplier", amount = status.stat("powerMultiplier")*1.2 }
    })  
end

function update(dt)

end

function uninit()
  
end