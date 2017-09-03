setName="fu_plebianset"

weaponBonus={
	{stat = "maxHealth", baseMultiplier = 1.20},
        {stat="grit", amount=0.15}
}


armorBonus={
	{stat = "shieldStaminaRegen", baseMultiplier = 1.15},
        {stat = "shieldBonusShield", amount = 0.15},
        {stat = "perfectBlockLimitRegen", baseMultiplier = 1.15}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
	end
end


function checkWeapons()
local weaponSword=weaponCheck({"shortsword","mace"})
local weaponShield=weaponCheck({"shield"})

	local weapons=weaponCheck({"shortsword","shield","mace"})
	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end