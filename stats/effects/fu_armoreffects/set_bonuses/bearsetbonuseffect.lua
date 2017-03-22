require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_bearset"

weaponBonuss1={
	{stat = "critChance", amount = 3.5}
}
weaponBonuss2={
	{stat = "powerMultiplier", baseMultiplier = 1.24}
}
armorBonus={
     {stat = "iceStatusImmunity", amount = 1},
     {stat = "grit", amount = 0.2},
     {stat = "biomecoldImmunity", amount = 1}
}



function init()
	setSEBonusInit(setName)
	armorBonusHandle=effect.addStatModifierGroup({})
	weaponBonusHandlePrimary=effect.addStatModifierGroup({})
	weaponBonusHandleAlt=effect.addStatModifierGroup({})
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
	effect.setStatModifierGroup( armorBonusHandle,setBonusMultiply(armorBonus,level))
end

function checkWeapons()
	local weapons=weaponCheck({"axe","hammer"})
	
	if weapons["twoHanded"] then --twohander
		effect.setStatModifierGroup(weaponBonusHandleAlt,setBonusMultiply(weaponBonuss2,level))
	else
		effect.setStatModifierGroup(weaponBonusHandleAlt,{})
	end
	
	if weapons["both"] then--matching dual wield
		effect.setStatModifierGroup(weaponBonusHandlePrimary,setBonusMultiply(weaponBonuss1,3*level))
	elseif (weapons["primary"] and weapons["alt"]) or weapons["twoHanded"] then--unmatching dual wield or 2-hander
		effect.setStatModifierGroup(weaponBonusHandlePrimary,setBonusMultiply(weaponBonuss1,2*level))
	elseif weapons["either"] then--only one hand has axe/hammer
		effect.setStatModifierGroup(weaponBonusHandlePrimary,setBonusMultiply(weaponBonuss1,level))
	else
		effect.setStatModifierGroup(weaponBonusHandlePrimary,{})
	end
end