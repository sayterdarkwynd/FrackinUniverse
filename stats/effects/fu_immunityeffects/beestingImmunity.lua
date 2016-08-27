function init()
  effect.addStatModifierGroup({
	{stat = "beestingImmunity", amount = 1}
  })
  -- effect.addStatModifierGroup({{stat = "beesting", baseMultiplier = -2}})
  -- effect.addStatModifierGroup({{stat = "beesting", tickDamagePercentage = 0}})
  script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end