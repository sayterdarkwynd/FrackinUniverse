require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_samuraiset"


weaponBonus={
	{stat = "powerMultiplier", amount = 0.15},
	{stat = "critChance", amount = 5}
}

weaponBonus2={
	{stat = "critChance", amount = 4},
	{stat = "critBonus", baseMultiplier = 1.10}
}

armorBonus={
	{stat = "physicalResistance", amount = 0.05}
}


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
local weaponSword=weaponCheck({"shortsword"})
local weaponShield=weaponCheck({"dagger"})
local weapons=weaponCheck({"shortsword","katana"})

	if weaponSword["either"] and weaponShield["either"] then--setting to either means we can have shortsword with anything else, or broadsword. setting to both means broadsword or dual wield shortswords.
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	elseif weapons["either"] then--setting to either means we can have shortsword with anything else, or broadsword. setting to both means broadsword or dual wield shortswords.
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus2)		
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end