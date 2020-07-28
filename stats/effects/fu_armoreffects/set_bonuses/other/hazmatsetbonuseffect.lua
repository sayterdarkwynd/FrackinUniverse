require "/stats/effects/fu_armoreffects/setbonuses_common.lua"


armorBonus={
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "radioactiveResistance", amount = 0.5}
}

setName="fu_hazmatset"

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end
