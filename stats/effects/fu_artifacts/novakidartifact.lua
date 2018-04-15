function init()
  effect.addStatModifierGroup({
    {stat = "radioactiveResistance", amount = config.getParameter("resist1")},
    {stat = "fireResistance", amount = config.getParameter("resist2")},
    {stat = "powerMultiplier", baseMultiplier = config.getParameter("damageBoost")}
  })
  
  script.setUpdateDelta(10)
end

function update(dt)
		
end

function uninit()

end