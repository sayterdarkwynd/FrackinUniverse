require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_conquerorset"

weaponBonus={
  {stat = "critChance", amount = 2},
  {stat = "critBonus", baseMultiplier = 1.3},
  {stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},	
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1}
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

function 
	checkWeapons()
	local weapons=weaponCheck({"plasma","electric"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end