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
	statusEffectName=config.getParameter("statusEffectName")
end

function update(dt)	
	if not checkSetWorn(self.setBonusCheck) then
		if type(statusEffectName)=="string" then
			local buffer=status.statusProperty("frackinPetStatEffectsMetatable",{})--thisStatusEffectId={"status1","status2"} format
			if buffer[statusEffectName] then
				buffer[statusEffectName]=nil
			end
			status.setStatusProperty("frackinPetStatEffectsMetatable",buffer)
		end
		status.removeEphemeralEffect("immortalresolve05")
		status.removeEphemeralEffect("genesifeed")
		effect.expire()
	else
		--[[mcontroller.controlModifiers({
			speedModifier = 1.07,
			airJumpModifier = 1.07
		})]]
		if type(statusEffectName)=="string" then
			local buffer=status.statusProperty("frackinPetStatEffectsMetatable",{})--thisStatusEffectId={"status1","status2"} format
			if not buffer[statusEffectName] then
				buffer[statusEffectName]={"immortalresolve05"}
			end
			status.setStatusProperty("frackinPetStatEffectsMetatable",buffer)
		end
		checkWeapons()
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