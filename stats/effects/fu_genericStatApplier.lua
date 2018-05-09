oldInit=init
oldUninit=uninit

function init()
	handler=effect.addStatModifierGroup(config.getParameter("stats",{}))
	--script.setUpdateDelta(0)
	if oldInit then oldInit() end
end

function uninit()
	effect.removeStatModifierGroup(handler)
	if oldUninit then oldUninit() end
end