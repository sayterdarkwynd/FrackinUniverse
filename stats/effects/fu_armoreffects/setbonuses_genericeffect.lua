require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setName=config.getParameter("setName","generic")
	weaponBonuses=config.getParameter("weaponBonuses",
		{
			{
				statEffects={}
				bonus={stat = "critChance", amount = 1},
				controlModifiers={},
				conditions={
					{allowedHands={"either"},bannedHands={"both"},tags={"pistol", "machinepistol"}}}
			},
			{
				statEffects={}
				bonus={stat = "critDamage", amount = 0.01},
				controlModifiers={},
				conditions={
					{allowedHands={"both"},bannedHands={},tags={"pistol", "machinepistol"}}}
			}
		}
	)
	
	biomeBonuses=config.getParameter("biomeBonuses",
		{
			{
				bonus={stat = "maxHealth", effectiveMultiplier = 1.1},
				controlModifiers={},
				conditions={
					{allowedBiomes={"ocean"},allowedTimes={"day"},bannedBiomes={"lush",bannedTimes={"night"}}},
					{allowedBiomes={"lush"},allowedTimes={"night"},bannedBiomes={"ocean",bannedTimes={"day"}}}
				
				}
			},
			{
				bonus={stat = "maxEnergy", effectiveMultiplier = 1.1},
				controlModifiers={},
				conditions={
					{allowedBiomes={"ocean"},allowedTimes={"night"},bannedBiomes={"lush",bannedTimes={"day"}}},
					{allowedBiomes={"lush"},allowedTimes={"day"},bannedBiomes={"ocean",bannedTimes={"night"}}}
				}
			}
			
		}
	)
	
	armorBonuses=config.getParameter("armorBonus",
		{
			statModifiers={},
			statuses={},
			controlModifiers={}
		}
	)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	
	setSEBonusInit(setName)
	
	for index,set in pairs(weaponBonuses) do
		effectHandlerList["weaponBonusHandle"..index]=effect.addStatModifierGroup({})
	end
	
	checkSet(0)
end

function update(dt)
	checkSet(dt)
end

function checkSet(dt)
	local check=checkSetWorn(self.setBonusCheck)
	doArmorBonus(check)
	checkWeapons(check)
	checkBiome(check)
end

function doArmorBonus()
	effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)




end

function checkWeapons(autofail)
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
			mcontroller.controlModifiers(set.controlModifiers)
		else
			effect.setStatModifierGroup(effectHandlerList["weaponBonusHandle"..index],{})
		end
	end
end

function checkBiome(autofail)
	local wType=world.type()
	local timeOfDay=world.timeOfDay()

end