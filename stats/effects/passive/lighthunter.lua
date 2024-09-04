require "/stats/effects/fu_statusUtil.lua"

function init()
	lightHunterEffects=effect.addStatModifierGroup({})
	self.powerBonus = config.getParameter("powerBonus",0)
	script.setUpdateDelta(10)
end

function update(dt)
	local lightLevel = getLight()
	local speedValue=1.0
	local specialValue=0
	if lightLevel >= 95 then
		specialValue=0.08
		speedValue = 1.2
	elseif lightLevel >= 80 then
		specialValue=0.07
		speedValue = 1.18
	elseif lightLevel >= 70 then
		specialValue=0.06
		speedValue = 1.16
	elseif lightLevel >= 60 then
		specialValue=0.05
		speedValue = 1.14
	elseif lightLevel >= 50 then
		specialValue=0.04
		speedValue = 1.11
	elseif lightLevel >= 40 then
		specialValue=0.02
		speedValue = 1.09
	elseif lightLevel >= 30 then
		speedValue = 1.06
	end
	if lightLevel>=30 then
		effect.setStatModifierGroup(lightHunterEffects, {
			{stat = "energyRegenPercentageRate", amount = 1.08 + self.powerBonus},
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.00+specialValue},
			{stat = "powerMultiplier", baseMultiplier = self.powerBonus + 1.00+specialValue}
		})
	else
		effect.setStatModifierGroup(lightHunterEffects,{})
	end
	applyFilteredModifiers({
		speedModifier = speedValue
	})
end

function uninit()
	effect.removeStatModifierGroup(lightHunterEffects)
	filterModifiers({},true)
end
