require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setName=config.getParameter("setName","generic")
	
	specialBonuses=config.getParameter("specialBonuses",
		{
			{
				conditions={
					{conditionType="hands",allowedHands={"either"},bannedHands={"both"},tags={"pistol", "machinepistol"}}
				},
				statEffects={}
				bonus={stat = "critChance", amount = 1},
				controlModifiers={},
				regen={
					{resource="health",amount=0.8},
					{resource="stunned",amount=-0.01}
				}
			},
			{
				conditions={
					{conditionType="hands",allowedHands={"both"},bannedHands={},tags={"pistol", "machinepistol"}}
				},
				statEffects={"critReady"}
				bonus={stat = "critDamage", amount = 0.01},
				controlModifiers={},
				regen={
					{resource="energy",amount=0.8}
				}
			},
			{
				conditions={
					{conditionType="biome",allowedBiomes={"ocean"},bannedBiomes={"lush"}},
					{conditionType="timeOfDay",allowedTimes={"night"},bannedTimes={"day"}}}
				},
				statEffects={"swimboost3"}
				bonus={stat = "maxHealth", effectiveMultiplier = 1.1},
				controlModifiers={}
			},
			{
				conditions={
					{allowedBiomes={"ocean"},allowedTimes={"night"},bannedBiomes={"lush",bannedTimes={"day"}}},
					{allowedBiomes={"lush"},allowedTimes={"day"},bannedBiomes={"ocean",bannedTimes={"night"}}}
				},
				bonus={stat = "maxEnergy", effectiveMultiplier = 1.1},
				controlModifiers={}
			}
			
		}
	)
	
	baseBonuses=config.getParameter("baseBonuses",
		{
			statModifiers={},
			statuses={},
			controlModifiers={}
			regen={}
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
	checkSpecial(check)
end

function doArmorBonus(fail)
	if fail then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
		for _,status in pairs(baseBonuses.statuses) do 
			status.removeEphemeralEffect(status)
		end
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,baseBonuses.statModifiers)
		for _,status in pairs(baseBonuses.statuses) do 
			status.addEphemeralEffect(status)
		end
		mcontroller.controlModifiers(baseBonuses.controlModifiers)
	end
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

function checkSpecial(autofail)
	local wType=world.type()
	local timeOfDay=world.timeOfDay()

end