function init()
    script.setUpdateDelta(10)
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*0.0023810714*math.max(0,1+status.stat("healingBonus"))}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
