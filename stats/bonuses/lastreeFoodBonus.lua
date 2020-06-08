function init()
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
  self.healingRateGood = 0.015
  if status.isResource("food") then
    self.foodValue = status.resource("food")
    if self.foodValue >= 35 then
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRateGood}})
	else	
		effect.setStatModifierGroup(bonusHandler,{})
    end
  end
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end