setName="fu_primusset"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.25},
	{stat = "critChance", amount = 3},
	{stat = "grit", amount = 0.5}
}

armorBonus={}

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
	local weapons=weaponCheck({"fist"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end