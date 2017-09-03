function init()
  effect.addStatModifierGroup({
    {stat = "maxEnergy", baseMultiplier = 1.35},
    {stat = "cosmicResistance", amount = 0.3},
    {stat = "powerMultiplier", baseMultiplier = 1.2}
  })
  script.setUpdateDelta(10)
end

function update(dt)
	
end

function uninit()

end