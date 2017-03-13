setName="fu_morphiteset"

weaponBonus={}

armorEffect={
  {stat = "ffextremeheatImmunity", amount = 1},
  {stat = "ffextremecoldImmunity", amount = 1},
  {stat = "ffextremeradiationImmunity", amount = 1},
  {stat = "sulphuricacidImmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
        armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end
