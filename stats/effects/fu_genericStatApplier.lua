local oldInitStatApplier=init
local oldUninitStatApplier=uninit

function init()
	if not genericStatHandler then
		genericStatHandler=effect.addStatModifierGroup(config.getParameter("stats",{}))
	else
		effect.setStatModifierGroup(genericStatHandler,config.getParameter("stats",{}))
	end
	if oldInitStatApplier then oldInitStatApplier() end
end

function uninit()
	effect.removeStatModifierGroup(genericStatHandler)
	genericStatHandler=nil
	if oldUninitStatApplier then oldUninitStatApplier() end
end