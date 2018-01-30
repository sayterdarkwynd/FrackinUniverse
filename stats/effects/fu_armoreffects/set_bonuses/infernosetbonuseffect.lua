require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_infernoset"

weaponBonus={
  {stat = "powerMultiplier", amount = 0.30}
}

armorBonus={
  {stat = "fireStatusImmunity", amount = 1},
  {stat = "biomeheatimmunity", amount = 1}
}

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
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function 
	checkWeapons()
	local weapons=weaponCheck({"flamethrower"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end