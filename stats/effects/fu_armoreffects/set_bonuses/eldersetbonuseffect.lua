require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_elderset"


weaponBonus={
	{stat = "powerMultiplier", amount = 0.25}
}

armorBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "insanityImmunity", amount = 1},
	{stat = "pusImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	armorBonusHandle=effect.addStatModifierGroup({})
	weaponBonusHandlePrimary=effect.addStatModifierGroup({})
	weaponBonusHandleAlt=effect.addStatModifierGroup({})
	self.timer = 0
        update(0)
end

function update(dt)
	self.timer = self.timer - dt
  -- randomly spawn a minion  
    
	if self.timer <= 0 then
	    local p = entity.position()
	    local parameters = {}
	    local type = "squidbeast"
	    --sb.logInfo("Spawning a slime from Slime armor. Type is %s",type)
	    parameters.persistent = false
	    parameters.damageTeamType = "friendly"
	    parameters.aggressive = true
	    parameters.damageTeam = 0
	    parameters.level = getLevel()
	    --sb.logInfo("Parameters for spawn are: %s",parameters)
	    world.spawnMonster(type, mcontroller.position(), parameters)    
		self.timer = math.random(220)+40
	end
    
	level=checkSetLevel(self.setBonusCheck)
	if level==0 then
		effect.expire()
	else
		checkArmor()
		checkWeapons()
	end
end

function checkArmor()
	effect.setStatModifierGroup( armorBonusHandle,setBonusMultiply(armorBonus,level))
end

function getLevel()
	if world.getProperty("ship.fuel") ~= nil then return 1 end
	if world.threatLevel then return world.threatLevel() end
	return 1
end

function checkWeapons()
	local weapons=weaponCheck({"elder"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandleAlt,setBonusMultiply(weaponBonus,level))
	else
		effect.setStatModifierGroup(weaponBonusHandleAlt,{})
	end
end