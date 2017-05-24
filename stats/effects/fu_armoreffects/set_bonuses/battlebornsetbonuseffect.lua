require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus={
	{stat = "maxHealth", baseMultiplier = 1.24},
	{stat = "powerMultiplier", baseMultiplier = 1.12},
	{stat = "poisonResistance", amount = 0.1},
	{stat = "physicalResistance", amount = 0.1}
}

armorEffect={
	{stat = "sulphuricImmunity", amount = 1}
}

setName="fu_battlebornset"

function init()
	setSEBonusInit(setName)
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	armorBonusHandle=effect.addStatModifierGroup({})
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkArmor()
	end
end

function checkArmor()
	if (world.type() == "metallicmoon") or (world.type() == "urbanwasteland") or (world.type() == "scorched") then
		effect.setStatModifierGroup(armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(armorBonusHandle,{})
	end
end