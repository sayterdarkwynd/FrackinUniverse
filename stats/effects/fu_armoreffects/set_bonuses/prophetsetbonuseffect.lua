require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_prophetset"

weaponBonus={
  {stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={}

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
		status.modifyResourcePercentage("health", 0.006 * dt)
	end
end

function 
	checkWeapons()
	local weapons=weaponCheck({"staff","wand"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end