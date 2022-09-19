require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_bearset2"

weaponBonus={
	{stat = "critChance", amount = 4.5},
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "iceStatusImmunity", amount = 1},
	{stat = "grit", amount = 0.3}
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
	local melee=weaponCheck({ "melee","dagger","knife","sword","shortsword","longsword","broadsword","rapier","katana","axe","greataxe","scythe","mace","hammer","spear","shortspear","quarterstaff","flail" })
	local axes=weaponCheck({ "axe","greataxe" })
	if (melee["either"] and melee["twoHanded"]) or axes["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
