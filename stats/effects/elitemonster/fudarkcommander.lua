local oldUpdate=update
local oldInit=init
local oldUninit=uninit

function init()
	local eType=world.entityType(entity.id())
	if not eType then return end
	regenHPPerSecond=config.getParameter("regenHPPerSecond") or 0
	didInit=true
	canRun=false
	for _,t in pairs(config.getParameter("acceptedEntityTypes") or {}) do
		if t==eType then
			canRun=true
			break
		end
	end
	if not canRun then return end
	if oldInit then oldInit() end
end

function update(dt)
	if not didInit then init() end
	if not canRun then return end
	if not regenHPPerSecond then regenHPPerSecond=config.getParameter("regenHPPerSecond") or 0 end
	healthPercent=status.resourcePercentage("health")
	if not status.statPositive("healingStatusImmunity") then
		--healthPercent=math.min(healthPercent+(regenHPPerSecond*dt),1.0)
		--status.setResourcePercentage("health",healthPercent)
		status.modifyResourcePercentage("health",regenHPPerSecond*dt)
	end

	if healthPercent>1.0 then healthPercent=1.0 elseif healthPercent<0 then healthPercent=0 end
	local opacity=string.format("%x",math.floor(healthPercent*255*0.5))
	if string.len(opacity)==1 then
		opacity="0"..opacity
	end
	effect.setParentDirectives("border=1;000000"..opacity..";00000000")
end

function uninit()
	if not canRun then return end
	if oldUninit then oldUninit() end
end