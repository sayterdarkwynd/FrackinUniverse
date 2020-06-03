function init()
	local alpha = math.floor(config.getParameter("alpha") * 255)
	effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
	effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}})
	script.setUpdateDelta(40)
	self.damageBonus=1.0+(getTechBonus()*0.01)
	powerHandler=effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.damageBonus}})
end

function getTechBonus()
	return 1 + status.stat("phaseattackBonus",0)
end

function update(dt)
	mcontroller.controlModifiers({speedModifier = 0.75})
	status.setResourcePercentage("energyRegenBlock", 1.0)
	if status.overConsumeResource("energy",(status.resourceMax("energy")*0.025)+2.5) then
		self.damageBonus=self.damageBonus*(1+(0.04*dt))
	end
	self.powerModifier = status.resource("energy")/status.stat("maxEnergy")

	effect.setStatModifierGroup(powerHandler,{{stat = "powerMultiplier", effectiveMultiplier = self.damageBonus}})
end