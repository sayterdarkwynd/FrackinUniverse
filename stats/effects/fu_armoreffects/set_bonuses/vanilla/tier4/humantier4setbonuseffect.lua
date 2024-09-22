require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_humantier4setnew"

-- weaponBonus={
	-- {stat = "powerMultiplier", effectiveMultiplier = 1.19}
-- }

armorBonus={
	{stat = "assaultrifleMastery", amount = 0.19},
	{stat = "shortswordMastery", amount = 0.19},
	{stat = "breathProtection", amount = 1}
}

function init()
	setSEBonusInit(setName)
	-- effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	-- checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	-- else

		-- checkWeapons()
	end
end

-- function checkWeapons()
	-- local weapons=weaponCheck({"assaultrifle","shortsword"})

	-- if weapons["either"] then
		-- effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	-- else
		-- effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	-- end
-- end
