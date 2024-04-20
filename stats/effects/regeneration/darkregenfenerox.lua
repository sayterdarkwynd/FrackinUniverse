require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"

function init()
	self.healingRate = 1.008 / config.getParameter("healTime", 220)
	script.setUpdateDelta(10)
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	--sb.logInfo("fenregen")
	nighttime = nighttimeCheck()
	underground = undergroundCheck()
	valueVal = 5

	if status.isResource("food") then
		self.foodValue = status.resource("food")
	else
		self.foodValue = 70
	end

	if nighttime or underground and (self.foodValue >= 45) then
		self.healingRate = 1.007 / config.getParameter("healTime", 220)
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate*math.max(0,1+status.stat("healingBonus"))}})

		status.setPersistentEffects("feneroxEffects", {
			{stat = "energyRegenPercentageRate", amount = config.getParameter("powerBonus",0)},
			{stat = "maxHealth", baseMultiplier = config.getParameter("powerBonus",0) + 1.08},
			{stat = "powerMultiplier", baseMultiplier = config.getParameter("powerBonus",0) + 1.08}
		})
	else
		effect.setStatModifierGroup(bonusHandler,{})
		status.clearPersistentEffects("feneroxEffects")
	end
end

function uninit()
	status.setPersistentEffects("feneroxEffects",{})
	effect.removeStatModifierGroup(bonusHandler)
end
