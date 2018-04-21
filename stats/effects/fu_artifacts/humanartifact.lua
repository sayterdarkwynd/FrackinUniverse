function init()
  effect.addStatModifierGroup({
    {stat = "maxEnergy", baseMultiplier = 1.20},
    {stat = "cosmicResistance", amount = 0.2},
    {stat = "powerMultiplier", baseMultiplier = 1.10}
  })
  script.setUpdateDelta(10)
end

function update(dt)
	
end

function uninit()

end