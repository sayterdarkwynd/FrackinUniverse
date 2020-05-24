function init()
	--[[sb.logInfo("Dark Commander init on %s. monster comparator: %s.",entity.id(),world.isMonster(entity.id()))
	if not world.isMonster(entity.id()) then
		--following is incorrect. actual problem is that starrypy has a blocker plugin that is typically run to 'protect' people. load of shit.--removed 'is pod monster' check due to params not being present on servers
		sb.logInfo("Dark Commander terminated in init.")
		effect.expire()
		return
	end]]
	--new implementation will be to apply via petspawner override
	regenHPPerSecond=config.getParameter("regenHPPerSecond",0)
	--sb.logInfo("Dark Commander init passed comparator. Regen value: %s",regenHPPerSecond)
end

function update(dt)
	if not regenHPPerSecond then regenHPPerSecond=config.getParameter("regenHPPerSecond",0) end
	healthPercent=status.resourcePercentage("health")
	if not status.statPositive("healingStatusImmunity") then
		healthPercent=math.min(healthPercent+(regenHPPerSecond*dt),1.0)
		status.setResourcePercentage("health",healthPercent)
	end

	if healthPercent>1.0 then healthPercent=1.0 elseif healthPercent<0 then healthPercent=0 end
	local opacity=string.format("%x",math.floor(healthPercent*255*0.5))
	if string.len(opacity)==1 then
		opacity="0"..opacity
	end
	effect.setParentDirectives("border=1;000000"..opacity..";00000000")
end