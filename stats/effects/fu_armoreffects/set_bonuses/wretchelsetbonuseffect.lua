require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_wretchelset"

weaponBonus={ }

armorBonus={ 
  {stat = "biooozeImmunity", amount = 1},
  {stat = "pusImmunity", amount = 1},
  {stat = "poisonStatusImmunity", amount = 1}
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
		effect.setStatModifierGroup(armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"shortsword","broadsword","whip","axe","hammer","spear","shortspear","dagger"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end