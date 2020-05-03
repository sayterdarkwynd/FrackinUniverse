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
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
end

function update(dt)	
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("genesifeed")
		effect.expire()
	else
		mcontroller.controlModifiers({
			speedModifier = 1.07,
			airJumpModifier = 1.07
		})
		checkWeapons()
		status.addEphemeralEffect("genesifeed")
		if status.resourcePercentage("health") < 1.0 then
		  status.modifyResourcePercentage("health", (1-status.resourcePercentage("health"))*0.05*dt)
		end
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{{stat="maxHealth",effectiveMultiplier=1+(status.stat("powerMultiplier")*0.1)}})
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