function init()
  effect.addStatModifierGroup({
    {stat = "protection", baseMultiplier = config.getParameter("protection")},
    {stat = "shieldBashChance", baseMultiplier = config.getParameter("shieldBash")},
    {stat = "poisonStatusImmunity", amount = 1}
  })
  
  script.setUpdateDelta(10)
end

function update(dt)
		
end

function uninit()

end