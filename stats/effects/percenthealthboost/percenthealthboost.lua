function init()
  script.setUpdateDelta(5)
  _x = effect.configParameter("healthDown", 0)
baseValue = effect.configParameter("healthDown",0)*(status.resourceMax("health"))

  if (status.resourceMax("health")) * _x >= 100.0 then
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
     else
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  end

end

function update(dt)

end

function uninit()
  
end