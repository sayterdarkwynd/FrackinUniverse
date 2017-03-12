setName="fu_evaset"

weaponBonus={}

armorBonus={
	{stat = "pusImmunity", amount = 1},
	{stat = "radioactiveResistance", amount = 0.25},
	{stat = "fireResistance", amount = 0.25},
	{stat = "iceResistance", amount = 0.25},
	{stat = "poisonResistance", amount = 0.25},
	{stat = "electricResistance", amount = 0.25},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1}	
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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
	local weapons=weaponCheck({"mininglaser"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end