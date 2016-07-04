function init()
  script.setUpdateDelta(5)
  _x = config.getParameter("healthDown", 0)
baseValue = config.getParameter("healthDown",0)*(status.resourceMax("energy"))

  if (status.resourceMax("energy")) * _x >= 100.0 then
     effect.addStatModifierGroup({{stat = "maxEnergy", amount = baseValue }})
     else
     effect.addStatModifierGroup({{stat = "maxEnergy", amount = baseValue }})
  end
  
end

function update(dt)

end

function uninit()
  
end