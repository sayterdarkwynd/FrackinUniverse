--world.sendEntityMessage(targetEntity, "applyStatusEffect", effectName, effectDuration, sourceEntity)

function init()
	--source=effect.sourceEntity()
	if not world.isMonster(entity.id()) then
		--because for some reason these parameters vanish on servers, this condition check is going dodo
		--[[overrideParams=world.callScriptedEntity(entity.id(),"monster.uniqueParameters")
		--sb.logInfo("podUuid:%s",overrideParams.podUuid)
		if not overrideParams.podUuid then
			effect.expire()
			return
		end]]
	--else
		effect.expire()
		return
	end
	regenHPPerSecond=config.getParameter("regenHPPerSecond",0)
end


function update(dt)
	if not regenHPPerSecond then return end
	healthPercent=math.min(status.resourcePercentage("health")+(regenHPPerSecond*dt),1.0)
	status.setResourcePercentage("health",healthPercent)

	if healthPercent>1.0 then healthPercent=1.0 elseif healthPercent<0 then healthPercent=0 end
	local opacity=string.format("%x",math.floor(healthPercent*255*0.5))
	if string.len(opacity)==1 then
		opacity="0"..opacity
	end
	effect.setParentDirectives("border=1;000000"..opacity..";00000000")
end







--[[{dink=world.callScriptedEntity(entity.id(),"monster.uniqueParameters")
	dink: {
		ownerUuid: db1c0e1297eb9940c3e7d5f0cfc5d,
		uniqueId: f1edc8e87fad83d8a24014961f22cb84,
		podUuid: cbf033f8677a435319c422f7e500698,
	},
	s: -65536
}]]