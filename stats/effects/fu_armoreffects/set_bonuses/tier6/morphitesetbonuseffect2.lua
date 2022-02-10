require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_morphiteset2"

armorEffect={
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end
