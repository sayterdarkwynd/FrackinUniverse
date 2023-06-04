function init()
	script.setUpdateDelta(10)
	conversionPercent=config.getParameter("conversionPercent",0.1)
	vitalPowerHandler=effect.addStatModifierGroup({})
end

function update(dt)
	effect.setStatModifierGroup(vitalPowerHandler,{{stat="maxHealth",effectiveMultiplier=1+(status.stat("powerMultiplier")*conversionPercent)}})
end

function uninit()
	effect.removeStatModifierGroup(vitalPowerHandler)
end