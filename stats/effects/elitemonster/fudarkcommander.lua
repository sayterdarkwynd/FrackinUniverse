function init()
	if not world.isMonster(entity.id()) then
		--removed 'is pod monster' check due to params not being present on servers
		effect.expire()
		return
	end
	regenHPPerSecond=config.getParameter("regenHPPerSecond",0)
end

function update(dt)
	if not regenHPPerSecond then return end
	
	healthPercent=status.resourcePercentage("health")
	if not status.statPositive("healingStatusImmunity")
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