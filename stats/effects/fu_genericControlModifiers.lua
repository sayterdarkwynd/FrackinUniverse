oldInit=init
oldUpdate=update

function init()
	controlModifierValues=config.getParameter("controlModifiers",{})
	if oldInit then oldInit() end
end

function update(dt)
	mcontroller.controlModifiers(controlModifierValues)
	if oldUpdate then oldUpdate(dt) end
end