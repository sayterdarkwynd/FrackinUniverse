setName="fu_xenoset"
armorStats={
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "wetImmunity", amount = 1},
	{stat = "physicalResistance", baseMultiplier = 0.20}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	effect.addStatModifierGroup(armorBonus)
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end