require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "physicalResistance", amount = 0.1}
}

weaponBonus2={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "poisonResistance", amount = 0.15}
	{stat = "sulphuricImmunity", amount = 0.15},
	{stat = "maxHealth", baseMultiplier = 1.16},
	{stat = "powerMultiplier", effectiveMultiplier = 1.16},
	{stat = "poisonResistance", amount = 0.15}
}

setName="fu_reptileset"

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
	local weaponSword=weaponCheck({"shortsword"})
	local weaponShield=weaponCheck({"shield"})
	local weaponSword2=weaponCheck({"axe"})

	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	elseif weaponSword2["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus2)		
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end