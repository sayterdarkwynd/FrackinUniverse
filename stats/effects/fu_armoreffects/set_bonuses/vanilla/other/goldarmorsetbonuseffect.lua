require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_goldarmorsetnew"

weaponBonus={
	{stat = "critChance", amount = 5}
}

armorBonus={
	{stat = "fuCharisma", baseMultiplier = 1.15},
	{stat = "grit", amount=0.3}
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
	end
end

function checkWeapons()
	local weapons=weaponCheck({"flail"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end