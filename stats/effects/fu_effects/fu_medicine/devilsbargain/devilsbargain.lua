require "/stats/effects/fu_statusUtil.lua"

function init()
	effect.addStatModifierGroup({
		{stat = "powerMultiplier", amount = 0.2},
		{stat = "physicalResistance", amount = 0.2},
		{stat = "fireResistance",amount = 0.2},
		{stat = "iceResistance", amount = 0.2},
		{stat = "poisonResistance", amount = 0.2},
		{stat = "electricResistance", amount = 0.2},
		{stat = "radioactiveResistance", amount = 0.2},
		{stat = "shadowResistance", amount = 0.2},
		{stat = "cosmicResistance", amount = 0.2},
		{stat = "maxHealth", baseMultiplier = 0.75},
		{stat = "maxEnergy", baseMultiplier = 0.75}
	})
end

function update(dt)
	applyFilteredModifiers({
		speedModifier = 1.55
	})
end

function uninit()
	filterModifiers({},true)
end
