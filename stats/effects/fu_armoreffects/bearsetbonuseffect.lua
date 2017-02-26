setName="fu_bearset"
weaponEffect={
    {stat = "critChance", amount = 15}
  }
armorBonus={
  {stat = "iceResistance", amount = 0.15},
  {stat = "coldimmunity", amount = 1}
  }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	effect.addStatModifierGroup(armorBonus)
	handler=effect.addStatModifierGroup({})
	bearPawCheck()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		bearPawCheck()
	end
end

function bearPawCheck()
	if weaponCheck("both",{"axe","hammer"},false) then
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end