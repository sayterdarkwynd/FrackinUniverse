setName="fu_underworldset"

weaponBonus={
	{stat = "critChance", amount = 2}
}

armorEffect={}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		
		checkWeapons()
	end
end

function 
	checkWeapons()
	local weapons=weaponCheck({"rifle","pistol","machinepistol"})
	if (weapons["twoHanded"] and weapons["either"]) or (weapons["primary"] and weapons["alt"]) then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end