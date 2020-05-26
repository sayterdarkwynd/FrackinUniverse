require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_xithricitesetkhe"

shellBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "aetherImmunity", amount = 1},
	
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	
	{ stat = "iceStatusImmunity", amount = 1},
	{ stat = "snowslowImmunity", amount = 1},
	{ stat = "slushslowImmunity", amount = 1},
	{ stat = "liquidnitrogenImmunity", amount = 1},
	{ stat = "iceslipImmunity", amount = 1},
	{ stat = "ffextremecoldImmunity", amount = 1},
	{ stat = "biomecoldImmunity", amount = 1},
	
	{ stat = "fireStatusImmunity", amount = 1},
	{ stat = "lavaImmunity", amount = 1},
	{ stat = "ffextremeheatImmunity", amount = 1},
	{ stat = "biomeheatImmunity", amount = 1}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "insanityImmunity", amount = 1},
	{stat = "waterbreathProtection", amount = 1},
	{stat = "pressureProtection", amount = 1},
	{stat = "extremepressureProtection", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.shellBonusHandle=effect.addStatModifierGroup({})
			
	checkShell()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	--statusEffectName=config.getParameter("statusEffectName")
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		--doesnt work, monsters dont have the resource damageAbsorption.
		--[[if type(statusEffectName)=="string" then
			local buffer=status.statusProperty("frackinPetStatEffectsMetatable",{})--thisStatusEffectId={"status1","status2"} format
			if buffer[statusEffectName] then
				buffer[statusEffectName]=nil
			end
			status.setStatusProperty("frackinPetStatEffectsMetatable",buffer)
		end]]
		status.removeEphemeralEffect("regeneratingshield_hp-100-10-3")
		status.removeEphemeralEffect("regeneratingshieldindicatordreamer")
		effect.expire()
	else
		--doesnt work, monsters dont have the resource damageAbsorption.
		--[[if type(statusEffectName)=="string" then
			local buffer=status.statusProperty("frackinPetStatEffectsMetatable",{})--thisStatusEffectId={"status1","status2"} format
			if not buffer[statusEffectName] then
				buffer[statusEffectName]={"regeneratingshield_hp-100-10-3","regeneratingshieldindicatordreamer"}
			end
			status.setStatusProperty("frackinPetStatEffectsMetatable",buffer)
		end]]
		checkShell()
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		status.addEphemeralEffect("regeneratingshield_hp-100-10-3")
		status.addEphemeralEffect("regeneratingshieldindicatordreamer")
	end
end


function checkShell()
		local rsp=status.stat("regeneratingshieldpercent")
		if rsp > 0.05 then
			effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,shellBonus)
		else
			effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,{})
		end
end