setName="fu_operativeset"

weaponBonus={}

armorBonus={
	{stat = "critChance", amount = 10},
	{stat = "critBonus", amount = 20}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
if not checkSetWorn(self.setBonusCheck) then
	effect.expire()
end
end
