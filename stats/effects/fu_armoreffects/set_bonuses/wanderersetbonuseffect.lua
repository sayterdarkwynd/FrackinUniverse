require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_wandererset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.15},
	{stat = "critBonus", baseMultiplier = 1.10}
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
	local weapons=weaponCheck({"energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end