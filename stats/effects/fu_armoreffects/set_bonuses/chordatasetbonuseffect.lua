setName="fu_chordataset"

weaponBonus={
        {stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={}

armorEffect={
	{ stat = "breathProtection", amount = 1.0 },
	{ stat = "insanityImmunity", amount = 1.0 },
        { stat = "poisonStatusImmunity", amount = 1.0 }
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	weaponBonusHandle=effect.addStatModifierGroup({})
	armorBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		checkArmor()
	end
end

function checkArmor()
if (world.type() == "bog") or (world.type() == "swamp") then
	effect.setStatModifierGroup(
	armorBonusHandle,armorBonus)
else
	effect.setStatModifierGroup(
	armorBonusHandle,{})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"spear","shortspear"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end