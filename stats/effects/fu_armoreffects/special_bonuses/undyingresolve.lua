function init()
	script.setUpdateDelta(10)
	buffPercent=config.getParameter("buffPercent",0.05)
	effectHandler=effect.addStatModifierGroup({})
end

function update(dt)
	effect.setStatModifierGroup(effectHandler,{{stat="protection",effectiveMultiplier=1.0+(buffPercent*(1-status.resourcePercentage("health")))}})
end

function uninit()
	effect.removeStatModifierGroup(effectHandler)
end