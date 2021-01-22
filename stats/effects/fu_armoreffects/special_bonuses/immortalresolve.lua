function init()
	script.setUpdateDelta(10)
	regenPercent=config.getParameter("regenPercent",0.05)
	--regenHandler=effect.addStatModifierGroup({})
end

function update(dt)
	--not switching to an hp regen effect as it's instead being applied via petspawner implementation
	--effect.setStatModifierGroup(regenHandler,{{stat="healthRegen",amount=status.resourceMax("health")*(1-status.resourcePercentage("health"))*regenPercent}})
	if not (world.isNpc(entity.id()) and status.resource("health")<1) then--just in case we DO use it on npcs. no idea why we would.
		if status.resourcePercentage("health") < 1.0 then
			status.modifyResourcePercentage("health", (1-status.resourcePercentage("health"))*regenPercent*dt*math.max(0,1+status.stat("healingBonus")))
		end
	else
		status.setResource("health",0)
	end
end

function uninit()
	--effect.removeStatModifierGroup(regenHandler)
end