require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_bonesteelset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.15}
}

armorBonus2={
	{stat = "physicalResistance", amount = 0.25},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.25}
}

armorBonus={
	{stat = "physicalResistance", amount = 0.10},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.25}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
			
	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		if (world.type() == "sulphuric") or (world.type() == "sulphuricdark") or (world.type() == "sulphuricocean") or (world.type() == "mountainous") then
			effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus2)
		else
			effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		end
		
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"broadsword","shortsword"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end