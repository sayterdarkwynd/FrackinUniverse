setName="fu_millenionset"

weaponBonus={
	{stat = "maxHealth", baseMultiplier = 1.20},
	{stat="grit", amount=0.25}
}


armorBonus={
	{stat = "blacktarImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.30},
	{stat = "shieldBonusShield", amount = 0.30},
	{stat = "perfectBlockLimitRegen", baseMultiplier = 1.30}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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
		checkWeapons()
	end
end


function checkWeapons()
	local weaponSword=weaponCheck({"shortsword"})
	local weaponShield=weaponCheck({"shield"})
	--local weapons=weaponCheck({"shortsword","shield"})
	
	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end