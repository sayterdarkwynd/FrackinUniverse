function init()
  script.setUpdateDelta(5)
  _x = config.getParameter("healthDown", 0)
baseValue = config.getParameter("healthDown",0)*(status.resourceMax("health"))

  --if (status.resourceMax("health")) * _x >= 100.0 then
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  --end

end

function update(dt)

end

function uninit()
  
end