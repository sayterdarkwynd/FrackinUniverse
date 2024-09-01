require "/scripts/vec2.lua"

function init()
	script.setUpdateDelta(10)

	effect.setParentDirectives(string.format("?multiply=ffffff%02x", (math.floor(config.getParameter("alpha") * 255))))

	self.timeElapsed=0
	self.flatCost=5.0
	self.percentCost=0.05
	self.damageGainRate=0.3
	self.multCap=3.0
	self.speedCostMult=0.1
	self.speedPenalty=0.75
	self.timeElapsedThreshold=6.0
	self.timeElapsedMult=1.0
	self.damageBonus=1.0+((1 + status.stat("phasetechBonus"))*0.01)

	powerHandler=effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.damageBonus}})
end

function update(dt)
	self.timeElapsed=(self.timeElapsed or 0)+dt
	mcontroller.controlModifiers({speedModifier = 0.75})
	status.setResourcePercentage("energyRegenBlock", 1.0)

	if status.overConsumeResource("energy",
		dt
		*(
			(status.resourceMax("energy")*self.percentCost)+
			(self.flatCost+(vec2.mag(mcontroller.velocity())*self.speedCostMult))
		)
		*self.damageBonus
		*(1+(math.max(0,self.timeElapsed-self.timeElapsedThreshold)*self.timeElapsedMult))
	) then
		if status.resourcePositive("energyRegenBlock") then
			self.damageBonus=math.min(self.damageBonus*(1+(self.damageGainRate*dt)),self.multCap)
		end
	end

	if self.damageBonus==self.multCap then
		status.removeEphemeralEffect("phaseattackindicatorcharging")
		status.addEphemeralEffect("phaseattackindicatorcharged",1)
	else
		status.addEphemeralEffect("phaseattackindicatorcharging",1)
	end

	effect.setStatModifierGroup(powerHandler,{{stat = "powerMultiplier", effectiveMultiplier = self.damageBonus}})
end
