require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_slimeset3"

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
	{stat = "fumudslowImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	
	handleBonuses(0,checkSetWorn(self.setBonusCheck))
	self.timer = math.max(math.random(6),math.random(6))
end

function update(dt)
	handleBonuses(dt,checkSetWorn(self.setBonusCheck))
end

function handleBonuses(dt,on)
	if on then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		applySetEffects()
		handleSpawn(dt)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkWeapons(not on)
end

function checkWeapons(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{}) return end

	local weapons=weaponCheck({"slime"})
	if weapons["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end

function handleSpawn(dt)
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 then
   	    if math.random(1000) <= (util.round(status.stat("critChance")*1000,0)+(self.usp or 0)) then
			self.usp=0.0
			self.type = "magmaslimespawned"
   	    else
			self.usp=(self.usp or 0)+(dt*10)
			self.type = "magmamicroslimespawned"
	    end
	    local parameters = {}
	    parameters.persistent = false
	    parameters.damageTeamType = "friendly"
	    parameters.aggressive = true
	    parameters.damageTeam = 0
	    parameters.level = checkSetLevel(self.setBonusCheck)
	    world.spawnMonster(self.type, mcontroller.position(), parameters)
        self.spawnTimer = math.max(math.random(12),math.random(12))
    end
end