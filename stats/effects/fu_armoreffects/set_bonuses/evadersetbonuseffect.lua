require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_evaderset"

weaponBonus={
	{stat = "physicalResistance", amount = 0.08}
}

armorBonus={
	{stat = "shieldBonusShield", amount = 0.20},
	{stat = "shieldStaminaRegen", amount = 0.20},
	{stat = "perfectBlockLimitRegen", baseMultiplier = 1.20}
}


function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
if not checkSetWorn(self.setBonusCheck) then
	effect.expire()
else
	
	checkWeapons()
end
end

function checkWeapons()
	local weapons=weaponCheck({"shield"})
	local weapons2=weaponCheck({"shortsword"})
if weapons["either"] and weapons2["either"] then
	effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
else
	effect.setStatModifierGroup(weaponBonusHandle,{})
end
end