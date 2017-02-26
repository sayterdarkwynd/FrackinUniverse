setName="fu_xithriciteset"

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "waterbreathProtection", amount = 1},	
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "shadowImmunity", amount = 1}, 
	{stat = "insanityImmunity", amount = 1}, 		
	{stat = "cosmicResistance", baseMultiplier = 0.75},
	{stat = "shadowResistance", baseMultiplier = 0.15},
	{stat = "radioactiveResistance", baseMultiplier = 0.50}
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