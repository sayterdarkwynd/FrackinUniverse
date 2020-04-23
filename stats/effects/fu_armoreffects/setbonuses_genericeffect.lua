require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 2}
}


armorBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "aetherImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1}
}


setName="fu_assassiniset"


function init()

	weaponBonuses=config.getParameter("weaponBonus",
		{
			{bonus={stat = "critChance", amount = 0},
				conditions={
					{allowedHands={"either"},bannedHands={"both"},tags={"pistol", "machinepistol"}}}
				}
		}
	)
	
	
	armorBonus=config.getParameter("armorBonus",{})
	
	setSEBonusInit(setName)
	
	for index,set in pairs(weaponBonuses) do
		effectHandlerList["weaponBonusHandle"..index]=effect.addStatModifierGroup({})
	end
	
	checkWeapons()
	checkBiome()
	
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		checkBiome()
	end
end


function checkWeapons()
	for index,set in pairs(weaponBonuses) do
		local whitelistPass={}
		local blacklistFail={}
		
		for _,condition in pairs(set.conditions) do
			conditioncheck=weaponCheck(condition.tags)
			for _,v in pairs(condition.bannedHands) do
				if conditioncheck[v] then
					table.insert(blacklistFail,v)
					break
				end
			end
			if #blacklistFail>0 then break end
			
			for _,v in pairs(condition.allowedHands) do
				if conditioncheck[v] then
					table.insert(whitelistPass,v)
					break
				end
			end
		end

		if #blacklistFail=0 and (#whitelistPass==#setconditions) then
			effect.setStatModifierGroup(effectHandlerList["weaponBonusHandle"..index],set.bonus)
		else
			effect.setStatModifierGroup(effectHandlerList["weaponBonusHandle"..index],{})
		end
	end
end

function checkBiome()



end