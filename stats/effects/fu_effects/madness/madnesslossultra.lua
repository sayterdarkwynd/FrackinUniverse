function init()
  script.setUpdateDelta(3)
  
  effect.addStatModifierGroup({
    {stat = "mentalProtection", amount = config.getParameter("mentalProtect")},
    {stat = "freudBonus", amount = config.getParameter("freudBonus")}
  })  
  
  
end

function update(dt)

end

function uninit()
  
end