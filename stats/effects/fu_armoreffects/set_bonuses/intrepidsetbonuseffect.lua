setName="fu_intrepidset"

weaponBonus={
	{stat = "critChance", amount = 2},
        {stat = "powerMultiplier", baseMultiplier = 1.20}
}

armorBonus={ 	
	{stat = "grit", amount = 0.12} 
}

armorEffect={
	{stat = "grit", amount = 0.15}
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
        if (world.type() == "mountainous4") or (world.type() == "mountainous3") or (world.type() == "mountainous2") or (world.type() == "mountainous") then
	effect.setStatModifierGroup(armorBonusHandle,armorBonus)
        else
	effect.setStatModifierGroup(armorBonusHandle,{})
	end
end

function 
	checkWeapons()
	local weapons=weaponCheck({"hammer","flail"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end