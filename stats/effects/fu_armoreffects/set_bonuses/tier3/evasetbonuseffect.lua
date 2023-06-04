require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_evaset"

armorBonus={
	{stat = "pusImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

	end
end
