require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_wandererset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15},
	{stat = "critBonus", baseMultiplier = 1.10}
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
	local weapons=weaponCheck({"energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end