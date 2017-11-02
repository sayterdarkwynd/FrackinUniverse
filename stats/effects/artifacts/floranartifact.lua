function init()
  effect.addStatModifierGroup({
    {stat = "maxHealth", baseMultiplier = config.getParameter("healthBonus")},
    {stat = "maxEnergy", baseMultiplier = config.getParameter("energyBonus")},
    {stat = "iceResistance", amount = config.getParameter("iceResistance",0)},
    {stat = "electricStatusImmunity", amount = 1}
  })
  
  script.setUpdateDelta(10)
end

function update(dt)
		
end

function uninit()

end