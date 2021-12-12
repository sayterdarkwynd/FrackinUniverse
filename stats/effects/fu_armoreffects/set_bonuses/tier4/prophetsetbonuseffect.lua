require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_prophetset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("glowyellow2")
		effect.expire()
	else
		checkWeapons()
		status.addEphemeralEffect("glowyellow2")
		setRegen(0.006)
	end
end

function checkWeapons()
	local weapons=weaponCheck({"staff","wand","quarterstaff"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end