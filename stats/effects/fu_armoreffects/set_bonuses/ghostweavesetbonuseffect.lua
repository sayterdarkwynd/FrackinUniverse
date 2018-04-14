require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_ghostweaveset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.25}
}

armorBonus={

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
		status.removeEphemeralEffect( "damagedefense" )
	else
		effect.setStatModifierGroup(armorBonusHandle,armorBonus)
		checkWeapons()
		status.addEphemeralEffect( "damagedefense" )
	end
end

function checkWeapons()
	local weapons=weaponCheck({"pistol","machinepistol"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end