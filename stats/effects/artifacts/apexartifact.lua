function init()
  effect.addStatModifierGroup({
    {stat = "maxHealth", baseMultiplier = config.getParameter("healthBonus")},
    {stat = "maxEnergy", baseMultiplier = config.getParameter("energyBonus")},
    {stat = "powerMultiplier", baseMultiplier = config.getParameter("attackBonus")},
    {stat = "protection", baseMultiplier = config.getParameter("defenseBonus")},

    {stat = "physicalResistance", amount = config.getParameter("physicalResistance",0)},
    {stat = "electricResistance", amount = config.getParameter("electricResistance",0)},
    {stat = "fireResistance", amount = config.getParameter("fireResistance",0)},
    {stat = "iceResistance", amount = config.getParameter("iceResistance",0)},
    {stat = "poisonResistance", amount = config.getParameter("poisonResistance",0)},
    {stat = "shadowResistance", amount = config.getParameter("shadowResistance",0)},
    {stat = "cosmicResistance", amount = config.getParameter("cosmicResistance",0)},
    {stat = "radioactiveResistance", amount = config.getParameter("radioactiveResistance",0)},
    
    {stat = "electricStatusImmunity", amount = 1}
  })
  
  script.setUpdateDelta(10)
end

function update(dt)
		
end

function uninit()

end