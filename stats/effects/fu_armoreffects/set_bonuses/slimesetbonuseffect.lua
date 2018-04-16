require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 6},
	{stat = "powerMultiplier", amount = 0.10}
}

armorBonus={
	{stat = "slimestickImmunity", amount = 1},
	{stat = "slimefrictionImmunity", amount = 1},
	{stat = "slimeImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "mudslowImmunity", amount = 1}
}

setName="fu_slimeset"

function init()
	self.timer = math.random(60)
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	self.timer = self.timer - dt

	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		
		checkWeapons()
	end
  -- randomly spawn a slime  

    if self.timer <= 0 then
		--monsterId=world.spawnMonster(type, mcontroller.position(), parameters)
	    --if world.entityExists(monsterId) then return end
		self.slimevar = math.random(2)
   	    if self.slimevar == 2 then
			self.type = "slime"
   	    else
			self.type = "microslime"
	    end      
	    local p = entity.position()
	    local parameters = {}
		local type = self.type
	    --sb.logInfo("Spawning a slime from Slime armor. Type is %s",type)

	    parameters.persistent = false
	    parameters.damageTeamType = "friendly"
	    parameters.aggressive = true
	    parameters.damageTeam = 0
	    parameters.level = getLevel()
	    --sb.logInfo("Parameters for spawn are: %s",parameters)
	    world.spawnMonster(type, mcontroller.position(), parameters)    
		self.timer = math.random(120)
    end
    
end

function getLevel()
	if world.getProperty("ship.fuel") ~= nil then return 1 end
	if world.threatLevel then return world.threatLevel() end
	return 1
end

function checkWeapons()
	local weapons=weaponCheck({"slime"})
	if weapons["both"] or (weapons["either"] and weapons["twoHanded"]) then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end