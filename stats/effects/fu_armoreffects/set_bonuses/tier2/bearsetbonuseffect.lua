require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_bearset"

armorBonus={
	{stat="hammerMastery",amount=0.2 },
	{stat="iceStatusImmunity",amount=1},
	{stat="slushslowImmunity",amount=1},
	{stat="grit",amount=0.2 }
}

weaponBonus={
	{stat="critChance",amount=3.5 },
	{stat="powerMultiplier",effectiveMultiplier=1.15 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	local melee=weaponCheck({ "melee" })
	local axes=weaponCheck({ "axe","greataxe" })
	if (melee["either"] and melee["twoHanded"]) or axes["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end