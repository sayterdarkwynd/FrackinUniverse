function init()
  effect.addStatModifierGroup({
    {stat = "critBonus", baseMultiplier = 1.20},
    {stat = "critChance", amount = 3}
  })
  
  script.setUpdateDelta(10)
end

function update(dt)
		
end

function uninit()

end