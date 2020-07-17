function init()
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	if status.isResource("food") and (status.resourcePercentage("food") >= 0.5) then
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*0.015*math.max(0,1+status.stat("healingBonus"))}})
	else
		effect.setStatModifierGroup(bonusHandler,{})
	end
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end