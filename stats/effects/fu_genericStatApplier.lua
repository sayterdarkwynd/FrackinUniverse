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
	if genericStatHandler then
		effect.removeStatModifierGroup(genericStatHandler)
	else
		sb.logInfo("fu_genericStatApplier.lua:uninit()::%s::%s",entity.entityType(),status.activeUniqueStatusEffectSummary())
	end
	genericStatHandler=nil
	if oldUninitStatApplier then oldUninitStatApplier() end
end