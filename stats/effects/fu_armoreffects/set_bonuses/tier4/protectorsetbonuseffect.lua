require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_protectorset"

weaponBonus={
	{stat = "critChance", amount = 4}
}

armorEffect={{stat = "maxEnergy", effectiveMultiplier = 1.05}}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
		status.removeEphemeralEffect( "damageheal" )
	else
		status.addEphemeralEffect( "damageheal" )
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "dagger","knife","sword","shortsword","longsword","broadsword","rapier","katana","axe","greataxe","scythe" })

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
