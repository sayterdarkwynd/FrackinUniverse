require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_protectorset"

weaponBonuss1={
	{stat = "critChance", baseMultiplier = 1.25}
}

armorBonus={}

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
	local weapons=weaponCheck({"shortsword","broadsword","dagger"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandlePrimary,setBonusMultiply(weaponBonus,level))
	else
		effect.setStatModifierGroup(weaponBonusHandlePrimary,{})
	end
end