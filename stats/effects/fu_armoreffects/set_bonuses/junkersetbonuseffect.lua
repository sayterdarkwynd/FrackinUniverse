require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_junkerset"

weaponBonus={ { stat = "powerMultiplier" , baseMultiplier = 1.25} }

armorBonus={
  {stat = "gasImmunity", amount = 1.0},
  {stat = "sulphuricImmunity", amount = 1.0},
  {stat = "energyRegenBlockTime", baseMultiplier = 1.75},
  {stat = "energyRegenPercentageRate", amount = 0.15}
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
	        checkWeapons()
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
	end
end


function 
	checkWeapons()
	local weapons=weaponCheck({ "grenadelauncher" })
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end