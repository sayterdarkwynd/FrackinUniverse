setName="fu_geistset"

weaponBonus={
	{stat = "critChance", amount = 9}
}

armorEffect={
  {stat = "maxHealth", baseMultiplier = 1.24},
  {stat = "sulphuricImmunity", amount = 1},
  {stat = "breathProtection", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)
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
	local weapons=weaponCheck({"dagger","broadsword","axe","hammer","shortsword","greataxe","spear","shortspear","quarterstaff"})
	if weapons["twoHanded"] or (weapons["primary"] and weapons["alt"]) then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end