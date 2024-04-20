function init()
	script.setUpdateDelta(5)
	self.healingRate = 1.0 / 150
	bonusHandler=effect.addStatModifierGroup({
		{stat = "shadowResistance", amount = 0.15},
		--{stat = "energyRegenPercentageRate", amount = 10}, {stat = "energyRegenBlockTime", effectiveMultiplier = 0}--no. you don't get to have unlimited energy.
		{stat = "energyRegenPercentageRate", baseMultiplier = 1.5 }, {stat = "energyRegenBlockTime", effectiveMultiplier = 0.9} --you get some FAIR values instead.
	})
	bonusHandler2=effect.addStatModifierGroup({})
end

function update(dt)
	if (world.entityType(entity.id())=="player") or status.resource("health")>=1 then
		effect.setStatModifierGroup(bonusHandler2,{{stat="healthRegen",amount=status.resourceMax("health")*self.healingRate*math.max(0,1+status.stat("healingBonus"))}})
	else
		effect.setStatModifierGroup(bonusHandler2,{})
	end
end

function uninit()
	if bonusHandler then
		effect.removeStatModifierGroup(bonusHandler)
	end
	if bonusHandler2 then
		effect.removeStatModifierGroup(bonusHandler2)
	end
end
