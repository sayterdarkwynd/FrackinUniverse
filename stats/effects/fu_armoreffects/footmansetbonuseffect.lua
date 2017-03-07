setName="fu_footmanset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.15}
}

armorBonus={
	{stat = "iceResistance", amount = 0.15}
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

function 
	checkWeapons()
	local weapons=weaponCheck({"shortsword","broadsword"})
if weapons["either"] then--setting to either means we can have shortsword with anything else, or broadsword. setting to both means broadsword or dual wield shortswords.
	effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
else
	effect.setStatModifierGroup(weaponBonusHandle,{})
end
end