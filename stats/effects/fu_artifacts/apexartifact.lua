function init()
  effect.addStatModifierGroup({
    {stat = "maxEnergy", baseMultiplier = config.getParameter("energyBonus")},
    {stat = "iceResistance", amount = config.getParameter("iceResistance",0)},
    {stat = "poisonResistance", amount = config.getParameter("poisonResistance",0)},
    {stat = "fumudslowImmunity", amount = 1},
    {stat = "iceslipImmunity", amount = 1},
    {stat = "jungleslowImmunity", amount = 1},
    {stat = "slushslowImmunity", amount = 1},
    {stat = "snowslowImmunity", amount = 1}
  })
  
  script.setUpdateDelta(10)
end

function update(dt)
		
end

function uninit()

end