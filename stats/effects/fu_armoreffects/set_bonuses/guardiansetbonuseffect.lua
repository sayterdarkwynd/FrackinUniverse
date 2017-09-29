setName="fu_guardianset"

weaponBonus={
	{stat = "grit", baseMultiplier = 1.25}
}
weaponBonus2={
	{stat = "powerMultiplier", baseMultiplier = 1.15}
}


armorBonus={
        {stat = "shieldBash", amount = 20},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.25},
        {stat = "shieldBonusShield", amount = 0.25}
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
	local weapons=weaponCheck({"shield"})
	local weapons2=weaponCheck({"mace"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
	if weapons2["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus2)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end	
end