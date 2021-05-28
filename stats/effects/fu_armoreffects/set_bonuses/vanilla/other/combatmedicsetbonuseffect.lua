require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_combatmedicsetnew"

weaponBonus={
	{stat = "critChance", amount = 2}
}

armorBonus={

}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
		setRegen(0.01)
	end
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end