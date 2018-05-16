oldInitControlModifier=init
oldUpdateControlModifier=update

function init()
	controlModifierValues=config.getParameter("controlModifiers",{})
	if oldInitControlModifier then oldInitControlModifier() end
end

function update(dt)
	mcontroller.controlModifiers(controlModifierValues)
	if oldUpdateControlModifier then oldUpdateControlModifier(dt) end
end