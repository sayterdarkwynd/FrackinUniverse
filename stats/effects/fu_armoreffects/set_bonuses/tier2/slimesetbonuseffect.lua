require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_slimeset"

weaponBonus={
	{stat = "critChance", amount = 5},
	{stat = "powerMultiplier", effectiveMultiplier = 1.10}
}

armorBonus={
	{stat = "maxHealth", effectiveMultiplier = 1.1},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "slimefrictionImmunity", amount = 1},
	{stat = "slimeImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "fumudslowImmunity", amount = 1}
}

function init()
	self.timer = math.max(math.random(6),math.random(6))
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

	if self.timer <= 0 then
		if math.random(1000) <= util.round(status.stat("critChance")*1000,0) then
			self.type = "slimespawned"
		else
			self.type = "microslimespawned"
		end
		local parameters = {}
		local team=world.entityDamageTeam(entity.id())
		parameters.persistent = false
		parameters.damageTeamType = team.type
		parameters.aggressive = true
		parameters.damageTeam = team.team
		parameters.level = checkSetLevel(self.setBonusCheck)
		world.spawnMonster(self.type, mcontroller.position(), parameters)
		self.timer = math.max(math.random(12),math.random(12))
	end
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