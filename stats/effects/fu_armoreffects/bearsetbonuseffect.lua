setName="fu_bearset"
weaponEffect={
    {stat = "critChance", amount = 7.5}
}
weaponEffect2={
    {stat = "critChance", amount = 15}
}
weaponEffect3={
    {stat = "critChance", amount = 22.5}
}
armorBonus={
  {stat = "iceResistance", amount = 0.15},
  {stat = "coldimmunity", amount = 1}
  }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorHandle=effect.addStatModifierGroup(armorBonus)
	weaponHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	if weaponCheck("both",{"axe","hammer"}) then--twohanded or matching dual wield
		effect.setStatModifierGroup(weaponHandle,weaponEffect3)
	elseif weaponCheck("primary",{"axe","hammer"}) and weaponCheck("alt",{"axe","hammer"}) then--unmatching dual wield
		effect.setStatModifierGroup(weaponHandle,weaponEffect2)
	elseif weaponCheck("either",{"axe","hammer"}) then--only one hand has axe/hammer
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end