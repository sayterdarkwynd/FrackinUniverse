require "/stats/effects/fu_statusUtil.lua"

function init()
	lightHunterEffects=effect.addStatModifierGroup({})
	self.powerBonus = config.getParameter("powerBonus",0)
	script.setUpdateDelta(10)
end

function update(dt)
	local lightLevel = getLight()
	if lightLevel >= 95 then
		effect.setStatModifierGroup(lightHunterEffects, {
			{stat = "energyRegenPercentageRate", amount = 1.08 + self.powerBonus},
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.08},
			{stat = "powerMultiplier", baseMultiplier = self.powerBonus + 1.08}
		})
		mcontroller.controlModifiers({ speedModifier = 1.20 })
	elseif lightLevel >= 80 then
		effect.setStatModifierGroup(lightHunterEffects, {
			{stat = "energyRegenPercentageRate", amount = 1.08 + self.powerBonus},
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.07},
			{stat = "powerMultiplier", baseMultiplier = self.powerBonus + 1.07}
		})
		mcontroller.controlModifiers({ speedModifier = 1.18 })
	elseif lightLevel >= 70 then
		effect.setStatModifierGroup(lightHunterEffects, {
			{stat = "energyRegenPercentageRate", amount = 1.08 + self.powerBonus},
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.06},
			{stat = "powerMultiplier", baseMultiplier = self.powerBonus + 1.06}
		})
		mcontroller.controlModifiers({ speedModifier = 1.16 })
	elseif lightLevel >= 60 then
		effect.setStatModifierGroup(lightHunterEffects, {
			{stat = "energyRegenPercentageRate", amount = 1.08 + self.powerBonus},
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.05},
			{stat = "powerMultiplier", baseMultiplier = self.powerBonus + 1.05}
		})
		mcontroller.controlModifiers({ speedModifier = 1.14 })
	elseif lightLevel >= 50 then
		effect.setStatModifierGroup(lightHunterEffects, {
			{stat = "energyRegenPercentageRate", amount = 1.08 + self.powerBonus},
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.04},
			{stat = "powerMultiplier", baseMultiplier = self.powerBonus + 1.04}
		})
		mcontroller.controlModifiers({ speedModifier = 1.11 })
	elseif lightLevel >= 40 then
		effect.setStatModifierGroup(lightHunterEffects, {
			{stat = "energyRegenPercentageRate", amount = 1.08 + self.powerBonus},
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.02},
			{stat = "powerMultiplier", baseMultiplier = self.powerBonus + 1.02}
		})
		mcontroller.controlModifiers({ speedModifier = 1.09 })
	elseif lightLevel >= 30 then
		effect.setStatModifierGroup(lightHunterEffects, {
			{stat = "energyRegenPercentageRate", amount = 1.08 + self.powerBonus},
			{stat = "maxHealth", baseMultiplier = self.powerBonus + 1.00},
			{stat = "powerMultiplier", baseMultiplier = self.powerBonus + 1.00}
		})
		mcontroller.controlModifiers({ speedModifier = 1.06 })
	else
		effect.setStatModifierGroup(lightHunterEffects,{})
	end
end

function uninit()
	effect.removeStatModifierGroup(lightHunterEffects)
end