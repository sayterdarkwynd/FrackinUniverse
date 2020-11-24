require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_genesifleshset"

weaponBonus={ {stat = "powerMultiplier", effectiveMultiplier = 1.15} }

armorEffect={
	{stat = "pusImmunity", amount = 1},
	{stat = "breathProtection", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		removePetBuffs()
		status.removeEphemeralEffect("vitalpower10")
		status.removeEphemeralEffect("immortalresolve05")
		status.removeEphemeralEffect("genesifeed")
		effect.expire()
	else
		setPetBuffs({"immortalresolve05"})
		checkWeapons()
		status.addEphemeralEffect("vitalpower10")
		status.addEphemeralEffect("immortalresolve05")
		status.addEphemeralEffect("genesifeed")
	end
end

function checkWeapons()
	local weapons=weaponCheck({"bioweapon"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end