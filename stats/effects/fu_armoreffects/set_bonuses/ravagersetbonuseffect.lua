require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_ravagerset"

weaponBonus={ 
	{stat = "powerMultiplier", amount = 0.25},
	{stat = "critBonus", baseMultiplier = 1.2} 
}

armorBonus2={}

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
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"rifle","sniperrifle"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end