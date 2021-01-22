function init()
	effect.addStatModifierGroup(config.getParameter("stats", {}))
end

function update(dt)
	mcontroller.controlModifiers(config.getParameter("controlModifiers", {}))
end

function uninit()
end
