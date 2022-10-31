require "/scripts/vec2.lua"

function init()
	local alpha = math.floor(config.getParameter("alpha") * 255)
	effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
	script.setUpdateDelta(10)
	self.damageBonus=1.0+(getTechBonus()*0.01)
	powerHandler=effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.damageBonus}})
end

function getTechBonus()
	return 1 + status.stat("phasetechBonus")
end

function update(dt)
	mcontroller.controlModifiers({speedModifier = 0.75})
	status.setResourcePercentage("energyRegenBlock", 1.0)
	local cost=5
	local vel=vec2.mag(mcontroller.velocity())/10.0
	cost=cost+vel
	cost=dt*((status.resourceMax("energy")*0.01*cost)+cost)

	if status.overConsumeResource("energy",cost) then
		if status.resourcePositive("energyRegenBlock") then
			self.damageBonus=math.min(self.damageBonus*(1+(0.08*dt)),3.0)
		end
	else
	end
	if self.damageBonus==3.0 then
		status.removeEphemeralEffect("phaseattackindicatorcharging")
		status.addEphemeralEffect("phaseattackindicatorcharged",1)
	else
		status.addEphemeralEffect("phaseattackindicatorcharging",1)
	end

	effect.setStatModifierGroup(powerHandler,{{stat = "powerMultiplier", effectiveMultiplier = self.damageBonus}})
end
