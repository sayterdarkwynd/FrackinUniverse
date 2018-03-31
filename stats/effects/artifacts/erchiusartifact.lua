function init()
  effect.addStatModifierGroup({
    {stat = "energyRegenPercentageRate", baseMultiplier = config.getParameter("energyBonus")}
  })
  
  script.setUpdateDelta(10)
end

function update(dt)
		
end

function uninit()

end