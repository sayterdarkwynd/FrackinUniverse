require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_warriorset"

weaponBonus={
  {stat = "powerMultiplier", amount = 0.10}
}

armorBonus={

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
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"shortsword","broadsword","whip","axe","hammer","spear","shortspear","dagger","longsword","rapier","mace","scythe","quarterstaff","katana"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end