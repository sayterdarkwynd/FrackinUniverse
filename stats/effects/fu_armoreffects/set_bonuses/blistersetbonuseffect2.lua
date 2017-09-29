require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_blisterset2"

weaponBonus={
	{stat = "critChance", amount = 8},
	{stat = "powerMultiplier", amount = 0.15}
}

armorBonus={ 
  {stat = "poisonStatusImmunity", amount = 1.0},
  {stat = "protoImmunity", amount = 1.0},
  {stat = "pusImmunity", amount = 1.0},
  {stat = "liquidnitrogenImmunity", amount = 1.0}
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
		status.removeEphemeralEffect( "glowyellow" )
	else
		status.addEphemeralEffect( "glowyellow" )
	end
end

function checkWeapons()
	local weapons=weaponCheck({"blister"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end

