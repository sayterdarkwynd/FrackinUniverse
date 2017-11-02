function init()
  effect.addStatModifierGroup({
    {stat = "critChance", amount = config.getParameter("critChance")},
    {stat = "maxBreath", amount = config.getParameter("breathBonus")}
  })
  
  script.setUpdateDelta(10)
end

function update(dt)
		
end

function uninit()

end