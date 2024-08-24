require "/stats/effects/fu_statusUtil.lua"

function init()
	self.powerBonus = config.getParameter("powerBonus",0)
	script.setUpdateDelta(10)
end

function update(dt)
	local lightLevel = getLight()
	local speedValue=1.0
	if lightLevel <= 55 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.2}
		})
		speedValue=1.2
	elseif lightLevel <= 65 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.1}
		})
		speedValue=1.1
	elseif lightLevel <= 75 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.0}
		})
		speedValue=1.0
	elseif lightLevel <= 85 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 0.9}
		})
		speedValue=0.9
	elseif lightLevel <= 95 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 0.8}
		})
		speedValue=0.9
	else
		status.clearPersistentEffects("trollEffects")
		speedValue=1.0
	end
	applyFilteredModifiers({ speedModifier = speedValue })
end

function uninit()
	filterModifiers({},true)
end
