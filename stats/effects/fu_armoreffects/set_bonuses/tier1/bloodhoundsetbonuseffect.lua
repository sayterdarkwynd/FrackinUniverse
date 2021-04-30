require "/scripts/status.lua"
require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_bloodhoundset"

weaponBonus={
	{stat="powerMultiplier",effectiveMultiplier=1.15},
	{stat="critChance",amount=2}
}

armorBonus={
	{stat="powerMultiplier",effectiveMultiplier=1.05}
}

armorBonus2={
	{stat="maxHealth",effectiveMultiplier=1.25},
	{stat="powerMultiplier",effectiveMultiplier=1.25}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})
	checkWeapons()
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkArmor()
		checkWeapons()
	end
end

function checkWeapons()
	local weaponSword=weaponCheck({"scythe","sniperrifle"})

	if weaponSword["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end

function checkArmor()
	if checkBiome({"urbanwasteland", "eden"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end