require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 4}
}

armorBonus={}


setName="fu_sanguineset"

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
		status.modifyResourcePercentage("health", 0.002 * dt)
		mcontroller.controlModifiers({
			speedModifier = 1.1
		})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"dagger","knife","whip","flail"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end