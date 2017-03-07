setName="fu_bearset"

weaponEffects1={
    {stat = "critChance", amount = 7.5}
}
weaponEffects2={
    {stat = "powerMultiplier", amount = 0.20}
}
armorBonus={
	{stat = "iceResistance", amount = 0.2},
	{stat = "grit", amount = 0.2},
	{stat = "coldimmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorHandle=effect.addStatModifierGroup({})
	weaponHandlePrimary=effect.addStatModifierGroup({})
	weaponHandleAlt=effect.addStatModifierGroup({})
	update(0)
end

function update(dt)
	level=checkSetLevel(self.setBonusCheck)
	if level==0 then
		effect.expire()
	else
		checkArmor()
		checkWeapons()
	end
end

function checkArmor()
	effect.setStatModifierGroup(armorHandle,setBonusMultiply(armorBonus,level))
end

function checkWeapons()
	local weapons=weaponCheck({"axe","hammer"})
	if weapons["twoHanded"] then --twohander
		effect.setStatModifierGroup(weaponHandleAlt,setBonusMultiply(weaponEffects2,level))
	else
		effect.setStatModifierGroup(weaponHandleAlt,{})
	end
	if weapons["both"] then--matching dual wield
		effect.setStatModifierGroup(weaponHandlePrimary,setBonusMultiply(weaponEffects1,3*level))
	elseif (weapons["primary"] and weapons["alt"]) or weapons["twoHanded"] then--unmatching dual wield or 2-hander
		effect.setStatModifierGroup(weaponHandlePrimary,setBonusMultiply(weaponEffects1,2*level))
	elseif weapons["either"] then--only one hand has axe/hammer
		effect.setStatModifierGroup(weaponHandlePrimary,setBonusMultiply(weaponEffects1,level))
	else
		effect.setStatModifierGroup(weaponHandlePrimary,{})
	end
end