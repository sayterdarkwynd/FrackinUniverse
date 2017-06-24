require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_valkyrieset"

weaponBonus={}

armorBonus={
  {stat = "extremepressureProtection", amount = 1},
  {stat = "biomeradiationImmunity", amount = 1},
  {stat = "ffextremeradiationImmunity", amount = 1},
  {stat = "breathProtection", amount = 1},
  {stat = "gasImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})
	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
	end
end