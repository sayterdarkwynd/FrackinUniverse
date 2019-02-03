require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 6},
	{stat = "powerMultiplier", effectiveMultiplier = 1.20}
}

armorBonus={
	{stat = "biooozeImmunity", amount = 1.0},
	{stat = "poisonStatusImmunity", amount = 1.0},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "slimefrictionImmunity", amount = 1},
	{stat = "slimeImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "mudslowImmunity", amount = 1}
}

setName="fu_slimeset3"

function init()
	self.timer = math.random(60)
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
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
            self.slimevar = math.random(2)
   	    if self.slimevar == 2 then
   	      self.type = "magmaslime"
   	    else
   	      self.type = "magmamicroslime"
	    end      
	    local p = entity.position()
	    local parameters = {}
	    local type = self.type
	    sb.logInfo("Spawning a slime from Slime armor. Type is %s",type)
	    parameters.persistent = false
	    parameters.damageTeamType = "friendly"
	    parameters.aggressive = true
	    parameters.damageTeam = 0
	    parameters.level = getLevel()
	    sb.logInfo("Parameters for spawn are: %s",parameters)
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
	if weapons["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end