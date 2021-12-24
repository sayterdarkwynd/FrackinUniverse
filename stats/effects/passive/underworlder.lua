require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"

function init()
	underWorlderEffects=effect.addStatModifierGroup({})
	self.sunIntensity = config.getParameter("sunIntensity",0)
	self.radiantWorld = 0.0
	script.setUpdateDelta(10)
end

function update(dt)
	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()
	local worldType=world.type()
	if (worldType == "desertwastesdark") or (worldType == "snowdark") or (worldType == "magmadark") or (worldType == "volcanicdark") or (worldType == "arborealdark") or (worldType == "arcticdark") or (worldType == "icewastedark") or (worldType == "midnight") or (worldType == "moon_shadow") or (worldType == "penumbra") or (worldType == "atropusdark") or (worldType == "infernusdark") or (worldType == "lightless") then
		self.radiantWorld = 0.4
	elseif (worldType == "desert") or (worldType == "desertwastes") or (worldType == "moon_desert") or (worldType == "savannah") or (worldType == "toxic") or (worldType == "moon_toxic") or (worldType == "alien") or (worldType == "magma") or (worldType == "scorchedcity") or (worldType == "barren") or (worldType == "protoworld") or (worldType == "chromatic") or (worldType == "irradiated") then
		self.radiantWorld = -0.4
	end

	if daytime then
		if underground then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.2},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.24},
				{stat = "maxHealth", amount = self.sunIntensity + 1.12}
			})
		elseif lightLevel > 95 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.001},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.14},
				{stat = "maxHealth", amount = self.sunIntensity + 1.02}
			})
		elseif lightLevel > 90 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.002},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.15},
				{stat = "maxHealth", amount = self.sunIntensity + 1.03}
			})
		elseif lightLevel > 80 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.003},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.16},
				{stat = "maxHealth", amount = self.sunIntensity + 1.04}
			})
		elseif lightLevel > 70 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.004},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.17},
				{stat = "maxHealth", amount = self.sunIntensity + 1.05}
			})
		elseif lightLevel > 65 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.005},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.18},
				{stat = "maxHealth", amount = self.sunIntensity + 1.06}
			})
		elseif lightLevel > 55 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.006},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.19},
				{stat = "maxHealth", amount = self.sunIntensity + 1.07}
			})
		elseif lightLevel > 45 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.007},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.2},
				{stat = "maxHealth", amount = self.sunIntensity + 1.08}
			})
		elseif lightLevel > 35 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.008},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.21},
				{stat = "maxHealth", amount = self.sunIntensity + 1.09}
			})
		elseif lightLevel > 25 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.009},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.22},
				{stat = "maxHealth", amount = self.sunIntensity + 1.1}
			})
		elseif lightLevel >= 0 then
			effect.setStatModifierGroup(underWorlderEffects, {
				{stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.1},
				{stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.23},
				{stat = "maxHealth", amount = self.sunIntensity + 1.12}
			})
		else
			effect.setStatModifierGroup(underWorlderEffects,{})
		end
	end
end

function uninit()
	effect.removeStatModifierGroup(underWorlderEffects)
end

