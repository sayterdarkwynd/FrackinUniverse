setName="fu_irradiumset"

weaponBonus1={
	{stat = "critChance", amount = 3},
	{stat = "radioactiveResistance", amount = 0.10}
}

armorBonus={ 
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponBonusHandlePrimary=effect.addStatModifierGroup({})
	weaponBonusHandleAlt=effect.addStatModifierGroup({})
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
	local knives=weaponCheck({"irradium"})
	
	if knives["either"] then
		effect.setStatModifierGroup(weaponBonusHandlePrimary,weaponBonus1)
	else
		effect.setStatModifierGroup(weaponBonusHandlePrimary,{})
	end
end