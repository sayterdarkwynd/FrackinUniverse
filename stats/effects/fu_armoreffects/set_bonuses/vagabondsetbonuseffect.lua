require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_vagabondset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.075}
}
weaponBonusBoth={
	{stat = "powerMultiplier", amount = 0.15}
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
		
	checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"pistol","machinepistol"})
	if weapons["both"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonusBoth)
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end