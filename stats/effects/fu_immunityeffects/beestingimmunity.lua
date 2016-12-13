function init()
  effect.addStatModifierGroup({
	{stat = "beestingImmunity", amount = 1},
	{stat = "poisonResistance", amount = 0.1}
  })
  script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
