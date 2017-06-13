setName="fu_monsterplateset"

weaponBonus={
	{stat = "critChance", amount = 5},
	{stat = "powerMultiplier", baseMultiplier = 1.15},  
}

armorBonus={
	{stat = "tarImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1},
	{stat = "fujungleslowImmunity", amount = 1},
	{stat = "fumudslowImmunity", amount = 1},
	{stat = "beestingImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1}
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
	local weapons=weaponCheck({"bow", "crossbow"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end