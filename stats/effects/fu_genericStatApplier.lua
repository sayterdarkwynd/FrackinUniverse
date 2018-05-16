oldInitStatApplier=init
oldUninitStatApplier=uninit

function init()
	handler=effect.addStatModifierGroup(config.getParameter("stats",{}))
	if oldInitStatApplier then oldInitStatApplier() end
end

function uninit()
	effect.removeStatModifierGroup(handler)
	if oldUninitStatApplier then oldUninitStatApplier() end
end