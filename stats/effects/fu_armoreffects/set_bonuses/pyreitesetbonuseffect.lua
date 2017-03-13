require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_pyreiteset"

weaponBonus={
  {stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "fireStatusImmunity", amount = 1},
        {stat = "lavaImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1}
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
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"pyreite"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end