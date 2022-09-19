require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_kingslayerset"

weaponBonus={
	{stat = "critChance", amount = 3}
}

armorEffect={
	{stat = "maxHealth", effectiveMultiplier = 1.12},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "breathProtection", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"melee","dagger","knife","sword","shortsword","longsword","broadsword","rapier","katana","axe","greataxe","scythe","mace","hammer","spear","shortspear","quarterstaff","flail"})

	if (weapons["either"] and (weapons["twoHanded"] or weapons["both"])) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
