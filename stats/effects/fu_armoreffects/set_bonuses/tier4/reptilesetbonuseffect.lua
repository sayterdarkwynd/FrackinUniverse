require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_reptileset"

weaponBonusSword={
	{stat = "physicalResistance", amount = 0.1}
}

weaponBonusAxe={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "maxHealth", effectiveMultiplier = 1.16},
	{stat = "powerMultiplier", effectiveMultiplier = 1.16}
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
	local weaponSword=weaponCheck({"sword","shortsword","longsword","broadsword","rapier","katana"})
	local weaponAxe=weaponCheck({"axe","shortspear"})
	local weaponShield=weaponCheck({"shield"})

	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonusSword)
	elseif weaponAxe["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonusAxe)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
