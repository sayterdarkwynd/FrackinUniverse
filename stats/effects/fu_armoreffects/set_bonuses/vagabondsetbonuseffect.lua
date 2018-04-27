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
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	
	checkWeapons()
	
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
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
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonusBoth)
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end