require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_glitchtier4setnew"

-- weaponBonus={
	-- {stat = "powerMultiplier", effectiveMultiplier = 1.19}
-- }

armorBonus={
	{stat = "maceMastery", amount = 0.19},
	{stat = "hammerMastery", amount = 0.19},
	{stat = "axeMastery", amount = 0.19},
	{stat = "greataxeMastery", amount = 0.19},
	{stat ="electricStatusImmunity" , amount = 1 }
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
	-- local weapons=weaponCheck({"axe","hammer","greataxe","mace"})

	-- if weapons["either"] then
		-- effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	-- else
		-- effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	-- end
-- end
