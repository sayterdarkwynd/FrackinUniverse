function init()
	handler=effect.addStatModifierGroup(config.getParameter("stats",{}))
	--script.setUpdateDelta(0)
end

function uninit()
	effect.removeStatModifierGroup(handler)
end