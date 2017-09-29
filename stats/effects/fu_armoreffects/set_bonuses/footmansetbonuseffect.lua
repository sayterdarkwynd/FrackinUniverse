require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 2},
	{stat = "critBonus", baseMultiplier = 1.15},
	{stat = "grit", amount = 0.15}
}

armorBonus={
	{stat = "shieldStaminaRegen", baseMultiplier = 1.17},
        {stat = "shieldBonusShield", baseMultiplier = 1.17},
        {stat = "perfectBlockLimitRegen", baseMultiplier = 1.17}
}

setName="fu_footmanset"


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
local weaponSword=weaponCheck({"shortsword","longsword","mace"})
local weaponShield=weaponCheck({"shield"})

	if weaponSword["either"] and weaponShield["either"] then--setting to either means we can have shortsword with anything else, or broadsword. setting to both means broadsword or dual wield shortswords.
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end