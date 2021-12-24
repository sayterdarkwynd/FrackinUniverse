require "/stats/effects/fu_statusUtil.lua"

function init()
	self.powerBonus = config.getParameter("powerBonus",0)
	script.setUpdateDelta(10)
end

function update(dt)
	local lightLevel = getLight()
	if lightLevel <= 55 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.2}
		})
		mcontroller.controlModifiers({ speedModifier = 1.2 })
	elseif lightLevel <= 65 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.1}
		})
		mcontroller.controlModifiers({ speedModifier = 1.1 })
	elseif lightLevel <= 75 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.0}
		})
		mcontroller.controlModifiers({ speedModifier = 1.0 })
	elseif lightLevel <= 85 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 0.9}
		})
		mcontroller.controlModifiers({ speedModifier = 0.9 })
	elseif lightLevel <= 95 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 0.8}
		})
		mcontroller.controlModifiers({ speedModifier = 0.8 })
	else
		status.clearPersistentEffects("trollEffects")
	end
end