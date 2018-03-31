setName="fu_hackerset"

weaponBonus={
  {stat = "critChance", amount = 1}
}

armorBonus={
	{stat = "energyRegenPercentageRate", baseMultiplier = 1.25},
	{stat = "gasImmunity", amount = 1}
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
	end
end

function checkWeapons()
	local weapons=weaponCheck({"flail"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end




