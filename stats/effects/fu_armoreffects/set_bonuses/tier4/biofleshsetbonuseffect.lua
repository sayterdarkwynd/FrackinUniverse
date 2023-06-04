require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_biofleshset"

weaponBonus={ {stat = "powerMultiplier", effectiveMultiplier = 1.15} }

armorBonus={
	{stat = "pusImmunity", amount = 1},
	{stat = "energyRegenPercentageRate", baseMultiplier = 1.05},
	{stat = "energyRegenBlockTime", baseMultiplier = 0.95}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.regenHandler=effect.addStatModifierGroup({})
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({
			speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.12,
			airJumpModifier = 1.12
		})
		checkWeapons()
		setRegen((0.01)*(((status.resourcePercentage("health") < 0.5) and 1 or 0)+((status.resourcePercentage("health") < 0.25) and 1 or 0)))
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
